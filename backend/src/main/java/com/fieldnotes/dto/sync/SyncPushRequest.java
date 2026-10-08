package com.fieldnotes.dto.sync;


import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.ArrayList;
import java.util.List;


public class SyncPushRequest {
    @Valid
    @NotNull
    @Size(max = 1000)
    private List<@NotNull CustomerSyncItem> customers = new ArrayList<>();
    @Valid
    @NotNull
    @Size(max = 1000)
    private List<@NotNull SiteSyncItem> sites = new ArrayList<>();
    @Valid
    @NotNull
    @Size(max = 1000)
    private List<@NotNull FieldNoteSyncItem> notes = new ArrayList<>();

    public static class CustomerSyncItem {
        @NotBlank @Size(max = 36)
        private String id;
        private Long baseVersion;
        public Long getBaseVersion() { return baseVersion; }
        public void setBaseVersion(Long value) { baseVersion = value; }
        @NotBlank @Size(max = 255)
        private String name;
        @Size(max = 16000)
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
        @NotBlank @Size(max = 36)
        private String id;
        private Long baseVersion;
        public Long getBaseVersion() { return baseVersion; }
        public void setBaseVersion(Long value) { baseVersion = value; }
        @NotBlank @Size(max = 36)
        private String customerId;
        @NotBlank @Size(max = 255)
        private String siteName;
        @Size(max = 16000)
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
        @NotBlank @Size(max = 36)
        private String id;
        private Long baseVersion;
        public Long getBaseVersion() { return baseVersion; }
        public void setBaseVersion(Long value) { baseVersion = value; }
        @NotBlank @Size(max = 36)
        private String siteId;
        @NotBlank @Size(max = 255)
        private String title;
        @Size(max = 16000)
        private String description;
        @Size(max = 255)
        private String location;
        @Min(-30610224000000L) @Max(253402300799999L)
        private Long dateTime; // epoch millis, MySQL DATETIME range
        @NotBlank @Pattern(regexp = "DRAFT|IN_PROGRESS|COMPLETED|PENDING")
        private String status;
        @Size(max = 2000000)
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
