package com.fieldnotes.service;

import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.exception.ConflictException;
import com.fieldnotes.model.Customer;
import com.fieldnotes.model.Site;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.SiteRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SiteService {

    private final SiteRepository siteRepository;
    private final CustomerRepository customerRepository;
    private final com.fieldnotes.repository.FieldNoteRepository notes;

    public SiteService(SiteRepository siteRepository, CustomerRepository customerRepository, com.fieldnotes.repository.FieldNoteRepository notes) {
        this.siteRepository = siteRepository;
        this.customerRepository = customerRepository;
        this.notes = notes;
    }

    @Transactional
    public SiteDto createSite(Long userId, SiteRequest request) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found or not owned by user: " + request.getCustomerId()));

        String siteId = (request.getId() != null && !request.getId().isBlank())
                ? request.getId()
                : UUID.randomUUID().toString();

        if (siteRepository.existsById(siteId)) throw new ConflictException("Record ID already exists");

        Site site = new Site(
                siteId,
                customer,
                request.getSiteName().trim(),
                request.getAddress()
        );

        site = siteRepository.saveAndFlush(site);
        return new SiteDto(site);
    }

    @Transactional(readOnly = true)
    public List<SiteDto> getSites(Long userId, String customerId) {
        List<Site> sites;
        if (customerId != null && !customerId.isBlank()) {
            sites = siteRepository.findByCustomerIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(customerId, userId);
        } else {
            sites = siteRepository.findByCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(userId);
        }

        return sites.stream().map(SiteDto::new).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SiteDto getSiteById(Long userId, String siteId) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));
        return new SiteDto(site);
    }

    @Transactional
    public SiteDto updateSite(Long userId, String siteId, SiteRequest request) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));

        if (request.getCustomerId() != null && !request.getCustomerId().equals(site.getCustomer().getId())) {
            Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Customer not found or not owned by user: " + request.getCustomerId()));
            site.setCustomer(customer);
        }

        if (!java.util.Objects.equals(request.getVersion(), site.getVersion())) throw new ConflictException("Stale record version");
        site.setSiteName(request.getSiteName().trim());
        site.setAddress(request.getAddress());
        site.setUpdatedAt(Instant.now());

        site = siteRepository.saveAndFlush(site);
        return new SiteDto(site);
    }

    @Transactional
    public void deleteSite(Long userId, String siteId) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));

        for (var note : notes.findBySiteId(site.getId())) {
            note.setDeleted(true);
            note.setUpdatedAt(Instant.now());
        }
        site.setDeleted(true);
        site.setUpdatedAt(Instant.now());
        siteRepository.saveAndFlush(site);
    }
}
