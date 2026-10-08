package com.fieldnotes.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

@Service
public class SyncSnapshotService {
    private final JdbcTemplate jdbc;
    public SyncSnapshotService(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    /** Read only small version columns, avoiding photo transfer for unchanged accounts. */
    @Transactional(readOnly=true)
    public String tag(Long userId) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            String[] queries = {
                "select id, version from customers where user_id=? order by id",
                "select s.id,s.version from sites s join customers c on c.id=s.customer_id where c.user_id=? order by s.id",
                "select n.id,n.version from field_notes n join sites s on s.id=n.site_id join customers c on c.id=s.customer_id where c.user_id=? order by n.id"
            };
            for (int i=0;i<queries.length;i++) {
                digest.update((byte)i);
                jdbc.query(queries[i], (org.springframework.jdbc.core.RowCallbackHandler) row -> digest.update((row.getString(1)+":"+row.getLong(2)+";").getBytes(StandardCharsets.UTF_8)),userId);
            }
            return "\""+HexFormat.of().formatHex(digest.digest())+"\"";
        } catch (NoSuchAlgorithmException ex) { throw new IllegalStateException(ex); }
    }
}
