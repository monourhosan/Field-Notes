package com.fieldnotes.dto.site;

import jakarta.validation.constraints.NotBlank;

public class SiteRequest {
    private String id; // Optional client-side generated UUID

    @NotBlank(message = "Customer ID is required")
    private String customerId;

    @NotBlank(message = "Site name is required")
    private String siteName;

    private String address;

    public SiteRequest() {}

    public SiteRequest(String id, String customerId, String siteName, String address) {
        this.id = id;
        this.customerId = customerId;
        this.siteName = siteName;
        this.address = address;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getSiteName() { return siteName; }
    public void setSiteName(String siteName) { this.siteName = siteName; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
}
