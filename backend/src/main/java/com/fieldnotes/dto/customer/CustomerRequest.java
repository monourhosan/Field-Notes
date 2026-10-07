package com.fieldnotes.dto.customer;

import jakarta.validation.constraints.NotBlank;

public class CustomerRequest {
    private String id; // Optional client-side generated UUID

    @NotBlank(message = "Customer name is required")
    private String name;

    private String contactInformation;

    public CustomerRequest() {}

    public CustomerRequest(String id, String name, String contactInformation) {
        this.id = id;
        this.name = name;
        this.contactInformation = contactInformation;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getContactInformation() { return contactInformation; }
    public void setContactInformation(String contactInformation) { this.contactInformation = contactInformation; }
}
