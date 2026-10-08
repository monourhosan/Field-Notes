package com.fieldnotes.service;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.customer.CustomerRequest;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.exception.ConflictException;
import com.fieldnotes.model.Customer;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;
    private final com.fieldnotes.repository.SiteRepository sites;
    private final com.fieldnotes.repository.FieldNoteRepository notes;

    public CustomerService(CustomerRepository customerRepository, UserRepository userRepository, com.fieldnotes.repository.SiteRepository sites, com.fieldnotes.repository.FieldNoteRepository notes) {
        this.customerRepository = customerRepository;
        this.userRepository = userRepository;
        this.sites = sites; this.notes = notes;
    }

    @Transactional
    public CustomerDto createCustomer(Long userId, CustomerRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        String customerId = (request.getId() != null && !request.getId().isBlank())
                ? request.getId()
                : UUID.randomUUID().toString();

        if (customerRepository.existsById(customerId)) throw new ConflictException("Record ID already exists");

        Customer customer = new Customer(
                customerId,
                user,
                request.getName().trim(),
                request.getContactInformation()
        );

        customer = customerRepository.saveAndFlush(customer);
        return new CustomerDto(customer);
    }

    @Transactional(readOnly = true)
    public List<CustomerDto> getCustomers(Long userId) {
        return customerRepository.findByUserIdAndDeletedFalse(userId)
                .stream()
                .map(CustomerDto::new)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CustomerDto getCustomerById(Long userId, String customerId) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found: " + customerId));
        return new CustomerDto(customer);
    }

    @Transactional
    public CustomerDto updateCustomer(Long userId, String customerId, CustomerRequest request) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found: " + customerId));

        if (!java.util.Objects.equals(request.getVersion(), customer.getVersion())) throw new ConflictException("Stale record version");
        customer.setName(request.getName().trim());
        customer.setContactInformation(request.getContactInformation());
        customer.setUpdatedAt(Instant.now());

        customer = customerRepository.saveAndFlush(customer);
        return new CustomerDto(customer);
    }

    @Transactional
    public void deleteCustomer(Long userId, String customerId) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found: " + customerId));

        Instant deletedAt = Instant.now();
        for (var site : sites.findByCustomerId(customer.getId())) {
            site.setDeleted(true);
            site.setUpdatedAt(deletedAt);
            for (var note : notes.findBySiteId(site.getId())) {
                note.setDeleted(true);
                note.setUpdatedAt(deletedAt);
            }
        }
        customer.setDeleted(true);
        customer.setUpdatedAt(Instant.now());
        customerRepository.saveAndFlush(customer);
    }
}
