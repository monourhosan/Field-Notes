package com.fieldnotes.dto.note;

import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public class FieldNoteRequest {
    private String id; // Optional client-side UUID

    @NotBlank(message = "Site ID is required")
    private String siteId;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private String location;
    private Instant dateTime;

    @NotBlank(message = "Status is required")
    private String status;

    private String photo;

    public FieldNoteRequest() {}

    public FieldNoteRequest(String id, String siteId, String title, String description, String location, Instant dateTime, String status, String photo) {
        this.id = id;
        this.siteId = siteId;
        this.title = title;
        this.description = description;
        this.location = location;
        this.dateTime = dateTime;
        this.status = status;
        this.photo = photo;
    }

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

    public Instant getDateTime() { return dateTime; }
    public void setDateTime(Instant dateTime) { this.dateTime = dateTime; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPhoto() { return photo; }
    public void setPhoto(String photo) { this.photo = photo; }
}
