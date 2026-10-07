package com.fieldnotes.dto.note;

import com.fieldnotes.model.FieldNote;
import java.time.Instant;

public class FieldNoteDto {
    private String id;
    private String siteId;
    private String siteName;
    private String customerId;
    private String customerName;
    private String title;
    private String description;
    private String location;
    private Instant dateTime;
    private String status;
    private String photo;
    private Instant createdAt;
    private Instant updatedAt;
    private boolean deleted;

    public FieldNoteDto() {}

    public FieldNoteDto(FieldNote note) {
        this.id = note.getId();
        this.siteId = note.getSite().getId();
        this.siteName = note.getSite().getSiteName();
        this.customerId = note.getSite().getCustomer().getId();
        this.customerName = note.getSite().getCustomer().getName();
        this.title = note.getTitle();
        this.description = note.getDescription();
        this.location = note.getLocation();
        this.dateTime = note.getDateTime();
        this.status = note.getStatus();
        this.photo = note.getPhoto();
        this.createdAt = note.getCreatedAt();
        this.updatedAt = note.getUpdatedAt();
        this.deleted = note.isDeleted();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getSiteId() { return siteId; }
    public void setSiteId(String siteId) { this.siteId = siteId; }

    public String getSiteName() { return siteName; }
    public void setSiteName(String siteName) { this.siteName = siteName; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Instant getDateTime() { return dateTime; }
    public void setDateTime(Instant dateTime) { this.dateTime = dateTime; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPhoto() { return photo; }
    public void setPhoto(String photo) { this.photo = photo; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
}
