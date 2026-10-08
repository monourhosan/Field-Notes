package com.fieldnotes.service;

import com.fieldnotes.dto.auth.AuthResponse;
import com.fieldnotes.dto.auth.LoginRequest;
import com.fieldnotes.dto.auth.RegisterRequest;
import com.fieldnotes.exception.BadRequestException;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.UserRepository;
import com.fieldnotes.security.JwtTokenProvider;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager,
                       JwtTokenProvider tokenProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.tokenProvider = tokenProvider;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (request.getPassword().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72) {
            throw new BadRequestException("Password exceeds 72 UTF-8 bytes");
        }
        request.setUsername(request.getUsername().trim());
        if (request.getUsername().length() < 3) {
            throw new BadRequestException("Username must contain at least 3 characters");
        }
        request.setEmail(request.getEmail().trim().toLowerCase(java.util.Locale.ROOT));
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username is already taken");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email is already registered");
        }

        User user = new User(
                request.getUsername().trim(),
                request.getEmail(),
                passwordEncoder.encode(request.getPassword())
        );

        user = userRepository.save(user);

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);

        String jwt = tokenProvider.generateToken(authentication);
        return new AuthResponse(jwt, user.getId(), user.getUsername(), user.getEmail());
    }

    public AuthResponse login(LoginRequest request) {
        if (request.getPassword().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72) {
            throw new BadRequestException("Password exceeds 72 UTF-8 bytes");
        }
        request.setUsername(request.getUsername().trim());
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);

        String jwt = tokenProvider.generateToken(authentication);
        User user = userRepository.findById(((com.fieldnotes.security.UserPrincipal) authentication.getPrincipal()).getId())
                .orElseThrow(() -> new BadRequestException("User not found"));

        return new AuthResponse(jwt, user.getId(), user.getUsername(), user.getEmail());
    }
}
