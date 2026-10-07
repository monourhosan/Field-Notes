package com.fieldnotes.dto.sync;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.note.FieldNoteDto;

import java.util.ArrayList;
import java.util.List;

public class SyncPullResponse {
    private List<CustomerDto> customers = new ArrayList<>();
    private List<SiteDto> sites = new ArrayList<>();
    private List<FieldNoteDto> notes = new ArrayList<>();
    private long serverTimestamp;

    public SyncPullResponse() {
        this.serverTimestamp = System.currentTimeMillis();
    }

    public List<CustomerDto> getCustomers() { return customers; }
    public void setCustomers(List<CustomerDto> customers) { this.customers = customers; }

    public List<SiteDto> getSites() { return sites; }
    public void setSites(List<SiteDto> sites) { this.sites = sites; }

    public List<FieldNoteDto> getNotes() { return notes; }
    public void setNotes(List<FieldNoteDto> notes) { this.notes = notes; }

    public long getServerTimestamp() { return serverTimestamp; }
    public void setServerTimestamp(long serverTimestamp) { this.serverTimestamp = serverTimestamp; }
}
