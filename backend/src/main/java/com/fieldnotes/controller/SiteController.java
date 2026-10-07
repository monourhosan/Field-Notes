package com.fieldnotes.controller;

import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.security.UserPrincipal;
import com.fieldnotes.service.SiteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sites")
public class SiteController {

    private final SiteService siteService;

    public SiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @PostMapping
    public ResponseEntity<SiteDto> createSite(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody SiteRequest request
    ) {
        SiteDto site = siteService.createSite(currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(site);
    }

    @GetMapping
    public ResponseEntity<List<SiteDto>> getSites(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam(value = "customerId", required = false) String customerId
    ) {
        List<SiteDto> sites = siteService.getSites(currentUser.getId(), customerId);
        return ResponseEntity.ok(sites);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SiteDto> getSiteById(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String siteId
    ) {
        SiteDto site = siteService.getSiteById(currentUser.getId(), siteId);
        return ResponseEntity.ok(site);
    }

    @PutMapping("/{id}")
    public ResponseEntity<SiteDto> updateSite(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String siteId,
            @Valid @RequestBody SiteRequest request
    ) {
        SiteDto site = siteService.updateSite(currentUser.getId(), siteId, request);
        return ResponseEntity.ok(site);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSite(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String siteId
    ) {
        siteService.deleteSite(currentUser.getId(), siteId);
        return ResponseEntity.noContent().build();
    }
}
