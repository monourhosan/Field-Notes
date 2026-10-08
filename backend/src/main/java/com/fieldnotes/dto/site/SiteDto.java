package com.fieldnotes.dto.site;

import com.fieldnotes.model.Site;
import java.time.Instant;


public class SiteDto {
    private Long version;
    public Long getVersion() { return version; }

    private String id;
    private String customerId;
    private String customerName;
    private String siteName;
    private String address;
    private Instant createdAt;
    private Instant updatedAt;
    private boolean deleted;

    public SiteDto() {}

    public SiteDto(Site site) {
        this.version = site.getVersion();
        this.id = site.getId();
        this.customerId = site.getCustomer().getId();
        this.customerName = site.getCustomer().getName();
        this.siteName = site.getSiteName();
        this.address = site.getAddress();
        this.createdAt = site.getCreatedAt();
        this.updatedAt = site.getUpdatedAt();
        this.deleted = site.isDeleted();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getSiteName() { return siteName; }
    public void setSiteName(String siteName) { this.siteName = siteName; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
}
