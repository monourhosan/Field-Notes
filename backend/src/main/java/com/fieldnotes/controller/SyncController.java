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
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    private final SyncService syncService;
    private final com.fieldnotes.service.SyncSnapshotService snapshots;

    public SyncController(SyncService syncService, com.fieldnotes.service.SyncSnapshotService snapshots) {
        this.syncService = syncService; this.snapshots = snapshots;
    }

    @PostMapping("/push")
    public ResponseEntity<SyncPushResponse> pushSync(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody SyncPushRequest request
    ) {
        SyncPushResponse response = syncService.pushSync(currentUser.getId(), request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pull")
    public ResponseEntity<SyncPullResponse> pullSync(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam(value = "since", required = false) Long sinceMillis,
            @RequestHeader(value="If-None-Match",required=false) String ifNoneMatch
    ) {
        Instant since = (sinceMillis != null && sinceMillis > 0)
                ? Instant.ofEpochMilli(sinceMillis)
                : Instant.EPOCH;

        // Compute before reading the payload: a concurrent commit can only cause an extra pull, never a missed edit.
        String tag = snapshots.tag(currentUser.getId());
        if (tag.equals(ifNoneMatch)) return ResponseEntity.status(304).eTag(tag).build();
        SyncPullResponse response = syncService.pullSync(currentUser.getId(), since);
        return ResponseEntity.ok().eTag(tag).body(response);
    }
}
