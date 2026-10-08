package com.fieldnotes.security;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.*;
import java.util.*;

/** Bound JSON allocation and authentication attempts before parsing or BCrypt. */
@Component @Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class RequestLimitsFilter extends OncePerRequestFilter {
    static final int MAX_BODY = 8 * 1024 * 1024;
    private final Map<String, Window> attempts = new HashMap<>();
    private record Window(long start, int count) {}
    private synchronized boolean allow(String address) {
        long now = System.currentTimeMillis();
        attempts.entrySet().removeIf(entry -> now - entry.getValue().start() >= 60_000);
        var window = attempts.get(address);
        if (window == null && attempts.size() >= 4096) return false;
        int count = window == null ? 1 : window.count() + 1;
        attempts.put(address, new Window(window == null ? now : window.start(), count));
        return count <= 20;
    }
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        if ("POST".equals(request.getMethod()) && request.getRequestURI().startsWith("/api/auth/") && !allow(request.getRemoteAddr())) {
            response.setHeader("Retry-After", "60"); fail(response,429,"Too many authentication attempts; retry in one minute"); return;
        }
        if (!List.of("POST","PUT","PATCH").contains(request.getMethod())) { chain.doFilter(request,response); return; }
        if (request.getContentLengthLong() > MAX_BODY) { fail(response,413,"Request exceeds 8 MiB"); return; }
        byte[] body = request.getInputStream().readNBytes(MAX_BODY + 1);
        if (body.length > MAX_BODY) { fail(response,413,"Request exceeds 8 MiB"); return; }
        chain.doFilter(new HttpServletRequestWrapper(request) {
            @Override public ServletInputStream getInputStream() {
                var input = new ByteArrayInputStream(body);
                return new ServletInputStream() {
                    @Override public int read() { return input.read(); }
                    @Override public boolean isFinished() { return input.available() == 0; }
                    @Override public boolean isReady() { return true; }
                    @Override public void setReadListener(ReadListener listener) { throw new UnsupportedOperationException("Synchronous request"); }
                };
            }
            @Override public BufferedReader getReader() { return new BufferedReader(new InputStreamReader(getInputStream(), java.nio.charset.StandardCharsets.UTF_8)); }
        },response);
    }
    private void fail(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status); response.setContentType("application/json");
        response.getWriter().write("{\"status\":"+status+",\"message\":\""+message+"\"}");
    }
}
