package com.fieldnotes.dto.customer;

import com.fieldnotes.model.Customer;
import java.time.Instant;


public class CustomerDto {
    private Long version;
    public Long getVersion() { return version; }

    private String id;
    private Long userId;
    private String name;
    private String contactInformation;
    private Instant createdAt;
    private Instant updatedAt;
    private boolean deleted;

    public CustomerDto() {}

    public CustomerDto(Customer customer) {
        this.version = customer.getVersion();
        this.id = customer.getId();
        this.userId = customer.getUser().getId();
        this.name = customer.getName();
        this.contactInformation = customer.getContactInformation();
        this.createdAt = customer.getCreatedAt();
        this.updatedAt = customer.getUpdatedAt();
        this.deleted = customer.isDeleted();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getContactInformation() { return contactInformation; }
    public void setContactInformation(String contactInformation) { this.contactInformation = contactInformation; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
}
