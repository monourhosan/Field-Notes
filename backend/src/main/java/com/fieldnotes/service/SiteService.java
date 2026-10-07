package com.fieldnotes.service;

import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.exception.ResourceNotFoundException;
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

    public SiteService(SiteRepository siteRepository, CustomerRepository customerRepository) {
        this.siteRepository = siteRepository;
        this.customerRepository = customerRepository;
    }

    @Transactional
    public SiteDto createSite(Long userId, SiteRequest request) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found or not owned by user: " + request.getCustomerId()));

        String siteId = (request.getId() != null && !request.getId().isBlank())
                ? request.getId()
                : UUID.randomUUID().toString();

        Site site = new Site(
                siteId,
                customer,
                request.getSiteName().trim(),
                request.getAddress()
        );

        site = siteRepository.save(site);
        return new SiteDto(site);
    }

    @Transactional(readOnly = true)
    public List<SiteDto> getSites(Long userId, String customerId) {
        List<Site> sites;
        if (customerId != null && !customerId.isBlank()) {
            sites = siteRepository.findByCustomerIdAndCustomerUserIdAndDeletedFalse(customerId, userId);
        } else {
            sites = siteRepository.findByCustomerUserIdAndDeletedFalse(userId);
        }

        return sites.stream().map(SiteDto::new).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SiteDto getSiteById(Long userId, String siteId) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));
        return new SiteDto(site);
    }

    @Transactional
    public SiteDto updateSite(Long userId, String siteId, SiteRequest request) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));

        if (request.getCustomerId() != null && !request.getCustomerId().equals(site.getCustomer().getId())) {
            Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Customer not found or not owned by user: " + request.getCustomerId()));
            site.setCustomer(customer);
        }

        site.setSiteName(request.getSiteName().trim());
        site.setAddress(request.getAddress());
        site.setUpdatedAt(Instant.now());

        site = siteRepository.save(site);
        return new SiteDto(site);
    }

    @Transactional
    public void deleteSite(Long userId, String siteId) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalse(siteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + siteId));

        site.setDeleted(true);
        site.setUpdatedAt(Instant.now());
        siteRepository.save(site);
    }
}
