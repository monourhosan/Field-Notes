package com.fieldnotes.service;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.note.FieldNoteDto;
import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.sync.SyncPullResponse;
import com.fieldnotes.dto.sync.SyncPushRequest;
import com.fieldnotes.dto.sync.SyncPushResponse;
import com.fieldnotes.model.Customer;
import com.fieldnotes.model.FieldNote;
import com.fieldnotes.model.Site;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import com.fieldnotes.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class SyncService {

    private final CustomerRepository customerRepository;
    private final SiteRepository siteRepository;
    private final FieldNoteRepository fieldNoteRepository;
    private final UserRepository userRepository;

    public SyncService(CustomerRepository customerRepository,
                       SiteRepository siteRepository,
                       FieldNoteRepository fieldNoteRepository,
                       UserRepository userRepository) {
        this.customerRepository = customerRepository;
        this.siteRepository = siteRepository;
        this.fieldNoteRepository = fieldNoteRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public SyncPushResponse pushSync(Long userId, SyncPushRequest request) {
        SyncPushResponse response = new SyncPushResponse();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        // 1. Process Customers
        for (SyncPushRequest.CustomerSyncItem cItem : request.getCustomers()) {
            try {
                Optional<Customer> existingOpt = customerRepository.findByIdAndUserId(cItem.getId(), userId);
                if (existingOpt.isPresent()) {
                    Customer existing = existingOpt.get();
                    Instant clientUpdated = (cItem.getUpdatedAt() != null) ? Instant.ofEpochMilli(cItem.getUpdatedAt()) : Instant.now();
                    // Last-Write-Wins: if client update is newer or same as existing
                    if (!clientUpdated.isBefore(existing.getUpdatedAt())) {
                        existing.setName(cItem.getName());
                        existing.setContactInformation(cItem.getContactInformation());
                        existing.setDeleted(cItem.isDeleted());
                        existing.setUpdatedAt(Instant.now());
                        customerRepository.save(existing);
                    }
                } else if (!cItem.isDeleted()) {
                    Customer newCustomer = new Customer(
                            cItem.getId(),
                            user,
                            cItem.getName(),
                            cItem.getContactInformation()
                    );
                    customerRepository.save(newCustomer);
                }
                response.getSyncedCustomerIds().add(cItem.getId());
            } catch (Exception ex) {
                response.getConflicts().add("Customer " + cItem.getId() + ": " + ex.getMessage());
            }
        }

        // 2. Process Sites
        for (SyncPushRequest.SiteSyncItem sItem : request.getSites()) {
            try {
                Optional<Site> existingOpt = siteRepository.findByIdAndCustomerUserId(sItem.getId(), userId);
                if (existingOpt.isPresent()) {
                    Site existing = existingOpt.get();
                    Instant clientUpdated = (sItem.getUpdatedAt() != null) ? Instant.ofEpochMilli(sItem.getUpdatedAt()) : Instant.now();
                    if (!clientUpdated.isBefore(existing.getUpdatedAt())) {
                        existing.setSiteName(sItem.getSiteName());
                        existing.setAddress(sItem.getAddress());
                        existing.setDeleted(sItem.isDeleted());
                        existing.setUpdatedAt(Instant.now());
                        siteRepository.save(existing);
                    }
                } else if (!sItem.isDeleted()) {
                    Customer customer = customerRepository.findByIdAndUserId(sItem.getCustomerId(), userId)
                            .orElse(null);
                    if (customer != null) {
                        Site newSite = new Site(
                                sItem.getId(),
                                customer,
                                sItem.getSiteName(),
                                sItem.getAddress()
                        );
                        siteRepository.save(newSite);
                    }
                }
                response.getSyncedSiteIds().add(sItem.getId());
            } catch (Exception ex) {
                response.getConflicts().add("Site " + sItem.getId() + ": " + ex.getMessage());
            }
        }

        // 3. Process Field Notes
        for (SyncPushRequest.FieldNoteSyncItem nItem : request.getNotes()) {
            try {
                Optional<FieldNote> existingOpt = fieldNoteRepository.findByIdAndSiteCustomerUserId(nItem.getId(), userId);
                if (existingOpt.isPresent()) {
                    FieldNote existing = existingOpt.get();
                    Instant clientUpdated = (nItem.getUpdatedAt() != null) ? Instant.ofEpochMilli(nItem.getUpdatedAt()) : Instant.now();
                    if (!clientUpdated.isBefore(existing.getUpdatedAt())) {
                        existing.setTitle(nItem.getTitle());
                        existing.setDescription(nItem.getDescription());
                        existing.setLocation(nItem.getLocation());
                        if (nItem.getDateTime() != null) {
                            existing.setDateTime(Instant.ofEpochMilli(nItem.getDateTime()));
                        }
                        existing.setStatus(nItem.getStatus());
                        if (nItem.getPhoto() != null) {
                            existing.setPhoto(nItem.getPhoto());
                        }
                        existing.setDeleted(nItem.isDeleted());
                        existing.setUpdatedAt(Instant.now());
                        fieldNoteRepository.save(existing);
                    }
                } else if (!nItem.isDeleted()) {
                    Site site = siteRepository.findByIdAndCustomerUserId(nItem.getSiteId(), userId).orElse(null);
                    if (site != null) {
                        FieldNote newNote = new FieldNote(
                                nItem.getId(),
                                site,
                                nItem.getTitle(),
                                nItem.getDescription(),
                                nItem.getLocation(),
                                nItem.getDateTime() != null ? Instant.ofEpochMilli(nItem.getDateTime()) : Instant.now(),
                                nItem.getStatus(),
                                nItem.getPhoto()
                        );
                        fieldNoteRepository.save(newNote);
                    }
                }
                response.getSyncedNoteIds().add(nItem.getId());
            } catch (Exception ex) {
                response.getConflicts().add("Note " + nItem.getId() + ": " + ex.getMessage());
            }
        }

        response.setServerTimestamp(System.currentTimeMillis());
        return response;
    }

    @Transactional(readOnly = true)
    public SyncPullResponse pullSync(Long userId, Instant since) {
        SyncPullResponse response = new SyncPullResponse();
        Instant querySince = (since != null) ? since : Instant.EPOCH;

        response.setCustomers(
                customerRepository.findByUserIdAndUpdatedAtAfter(userId, querySince)
                        .stream().map(CustomerDto::new).collect(Collectors.toList())
        );

        response.setSites(
                siteRepository.findByCustomerUserIdAndUpdatedAtAfter(userId, querySince)
                        .stream().map(SiteDto::new).collect(Collectors.toList())
        );

        response.setNotes(
                fieldNoteRepository.findBySiteCustomerUserIdAndUpdatedAtAfter(userId, querySince)
                        .stream().map(FieldNoteDto::new).collect(Collectors.toList())
        );

        response.setServerTimestamp(System.currentTimeMillis());
        return response;
    }
}
