package com.fieldnotes.dto.customer;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CustomerRequest {
    @jakarta.validation.constraints.PositiveOrZero
    private Long version;
    public Long getVersion() { return version; }
    public void setVersion(Long value) { version = value; }
    @Size(max = 36)
    private String id; // Optional client-side generated UUID

    @NotBlank(message = "Customer name is required")
    @Size(max = 255)
    private String name;

    @Size(max = 16000)
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
