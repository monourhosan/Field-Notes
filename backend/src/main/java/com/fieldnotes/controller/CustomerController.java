package com.fieldnotes.controller;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.customer.CustomerRequest;
import com.fieldnotes.security.UserPrincipal;
import com.fieldnotes.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @PostMapping
    public ResponseEntity<CustomerDto> createCustomer(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody CustomerRequest request
    ) {
        CustomerDto customer = customerService.createCustomer(currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(customer);
    }

    @GetMapping
    public ResponseEntity<List<CustomerDto>> getCustomers(
            @AuthenticationPrincipal UserPrincipal currentUser
    ) {
        List<CustomerDto> customers = customerService.getCustomers(currentUser.getId());
        return ResponseEntity.ok(customers);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustomerDto> getCustomerById(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String customerId
    ) {
        CustomerDto customer = customerService.getCustomerById(currentUser.getId(), customerId);
        return ResponseEntity.ok(customer);
    }

    @PutMapping("/{id}")
    public ResponseEntity<CustomerDto> updateCustomer(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String customerId,
            @Valid @RequestBody CustomerRequest request
    ) {
        CustomerDto customer = customerService.updateCustomer(currentUser.getId(), customerId, request);
        return ResponseEntity.ok(customer);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCustomer(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String customerId
    ) {
        customerService.deleteCustomer(currentUser.getId(), customerId);
        return ResponseEntity.noContent().build();
    }
}
