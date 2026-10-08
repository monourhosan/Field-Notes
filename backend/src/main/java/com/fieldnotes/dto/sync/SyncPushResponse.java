package com.fieldnotes.dto.sync;

import java.util.ArrayList;
import java.util.List;

public class SyncPushResponse {
    private final java.util.Map<String, Long> customerVersions = new java.util.HashMap<>();
    private final java.util.Map<String, Long> siteVersions = new java.util.HashMap<>();
    private final java.util.Map<String, Long> noteVersions = new java.util.HashMap<>();
    public java.util.Map<String, Long> getCustomerVersions() { return customerVersions; }
    public java.util.Map<String, Long> getSiteVersions() { return siteVersions; }
    public java.util.Map<String, Long> getNoteVersions() { return noteVersions; }
    private List<String> syncedCustomerIds = new ArrayList<>();
    private List<String> syncedSiteIds = new ArrayList<>();
    private List<String> syncedNoteIds = new ArrayList<>();
    private List<String> conflicts = new ArrayList<>();
    private long serverTimestamp;

    public SyncPushResponse() {
        this.serverTimestamp = System.currentTimeMillis();
    }

    public List<String> getSyncedCustomerIds() { return syncedCustomerIds; }
    public void setSyncedCustomerIds(List<String> syncedCustomerIds) { this.syncedCustomerIds = syncedCustomerIds; }

    public List<String> getSyncedSiteIds() { return syncedSiteIds; }
    public void setSyncedSiteIds(List<String> syncedSiteIds) { this.syncedSiteIds = syncedSiteIds; }

    public List<String> getSyncedNoteIds() { return syncedNoteIds; }
    public void setSyncedNoteIds(List<String> syncedNoteIds) { this.syncedNoteIds = syncedNoteIds; }

    public List<String> getConflicts() { return conflicts; }
    public void setConflicts(List<String> conflicts) { this.conflicts = conflicts; }

    public long getServerTimestamp() { return serverTimestamp; }
    public void setServerTimestamp(long serverTimestamp) { this.serverTimestamp = serverTimestamp; }
}
