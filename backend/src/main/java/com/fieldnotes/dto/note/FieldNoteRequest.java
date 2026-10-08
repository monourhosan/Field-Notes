package com.fieldnotes.dto.note;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;

public class FieldNoteRequest {
    @jakarta.validation.constraints.PositiveOrZero
    private Long version;
    public Long getVersion() { return version; }
    public void setVersion(Long value) { version = value; }
    @Size(max = 36)
    private String id; // Optional client-side UUID

    @NotBlank(message = "Site ID is required")
    @Size(max = 36)
    private String siteId;

    @NotBlank(message = "Title is required")
    @Size(max = 255)
    private String title;

    @Size(max = 16000)
    private String description;
    @Size(max = 255)
    private String location;
    private Instant dateTime;

    @jakarta.validation.constraints.AssertTrue(message = "Inspection date must be between years 1000 and 9999 UTC")
    public boolean isDateSupported() {
        return dateTime == null || (!dateTime.isBefore(Instant.parse("1000-01-01T00:00:00Z"))
                && dateTime.isBefore(Instant.parse("+10000-01-01T00:00:00Z")));
    }

    @NotBlank(message = "Status is required")
    @Pattern(regexp = "DRAFT|IN_PROGRESS|COMPLETED|PENDING")
    private String status;

    @Size(max = 2000000)
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
