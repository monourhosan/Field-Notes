package com.fieldnotes.dto.sync;

import com.fieldnotes.dto.customer.CustomerRequest;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.dto.note.FieldNoteRequest;

import java.util.ArrayList;
import java.util.List;

public class SyncPushRequest {
    private List<CustomerSyncItem> customers = new ArrayList<>();
    private List<SiteSyncItem> sites = new ArrayList<>();
    private List<FieldNoteSyncItem> notes = new ArrayList<>();

    public static class CustomerSyncItem {
        private String id;
        private String name;
        private String contactInformation;
        private boolean deleted;
        private Long updatedAt; // epoch millis

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getContactInformation() { return contactInformation; }
        public void setContactInformation(String contactInformation) { this.contactInformation = contactInformation; }
        public boolean isDeleted() { return deleted; }
        public void setDeleted(boolean deleted) { this.deleted = deleted; }
        public Long getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Long updatedAt) { this.updatedAt = updatedAt; }
    }

    public static class SiteSyncItem {
        private String id;
        private String customerId;
        private String siteName;
        private String address;
        private boolean deleted;
        private Long updatedAt;

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getCustomerId() { return customerId; }
        public void setCustomerId(String customerId) { this.customerId = customerId; }
        public String getSiteName() { return siteName; }
        public void setSiteName(String siteName) { this.siteName = siteName; }
        public String getAddress() { return address; }
        public void setAddress(String address) { this.address = address; }
        public boolean isDeleted() { return deleted; }
        public void setDeleted(boolean deleted) { this.deleted = deleted; }
        public Long getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Long updatedAt) { this.updatedAt = updatedAt; }
    }

    public static class FieldNoteSyncItem {
        private String id;
        private String siteId;
        private String title;
        private String description;
        private String location;
        private Long dateTime; // epoch millis
        private String status;
        private String photo;
        private boolean deleted;
        private Long updatedAt;

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getSiteId() { return siteId; }
        public void setSiteId(String siteId) { this.siteId = siteId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getLocation() { return location; }
        public void setLocation(String location) { this.location = location; }
        public Long getDateTime() { return dateTime; }
        public void setDateTime(Long dateTime) { this.dateTime = dateTime; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getPhoto() { return photo; }
        public void setPhoto(String photo) { this.photo = photo; }
        public boolean isDeleted() { return deleted; }
        public void setDeleted(boolean deleted) { this.deleted = deleted; }
        public Long getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Long updatedAt) { this.updatedAt = updatedAt; }
    }

    public List<CustomerSyncItem> getCustomers() { return customers; }
    public void setCustomers(List<CustomerSyncItem> customers) { this.customers = customers; }

    public List<SiteSyncItem> getSites() { return sites; }
    public void setSites(List<SiteSyncItem> sites) { this.sites = sites; }

    public List<FieldNoteSyncItem> getNotes() { return notes; }
    public void setNotes(List<FieldNoteSyncItem> notes) { this.notes = notes; }
}
