package com.fieldnotes.controller;

import com.fieldnotes.dto.sync.SyncPullResponse;
import com.fieldnotes.dto.sync.SyncPushRequest;
import com.fieldnotes.dto.sync.SyncPushResponse;
import com.fieldnotes.security.UserPrincipal;
import com.fieldnotes.service.SyncService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    private final SyncService syncService;

    public SyncController(SyncService syncService) {
        this.syncService = syncService;
    }

    @PostMapping("/push")
    public ResponseEntity<SyncPushResponse> pushSync(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestBody SyncPushRequest request
    ) {
        SyncPushResponse response = syncService.pushSync(currentUser.getId(), request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pull")
    public ResponseEntity<SyncPullResponse> pullSync(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam(value = "since", required = false) Long sinceMillis
    ) {
        Instant since = (sinceMillis != null && sinceMillis > 0)
                ? Instant.ofEpochMilli(sinceMillis)
                : Instant.EPOCH;

        SyncPullResponse response = syncService.pullSync(currentUser.getId(), since);
        return ResponseEntity.ok(response);
    }
}
