package com.fieldnotes.service;
import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.note.FieldNoteDto;
import com.fieldnotes.dto.sync.*;
import com.fieldnotes.model.*;
import com.fieldnotes.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.Objects;

@Service
public class SyncService {
    private final CustomerRepository customers;
    private final SiteRepository sites;
    private final FieldNoteRepository notes;
    private final UserRepository users;
    public SyncService(CustomerRepository customers, SiteRepository sites, FieldNoteRepository notes, UserRepository users) {
        this.customers = customers; this.sites = sites; this.notes = notes; this.users = users;
    }
    // Storage failures roll back the entire batch. Stale edits remain pending for explicit review.
    @Transactional
    public SyncPushResponse pushSync(Long userId, SyncPushRequest request) {
        var response = new SyncPushResponse();
        var user = users.findById(userId).orElseThrow();
        for (var item : request.getCustomers()) {
            var current = customers.findById(item.getId()).orElse(null);
            if (current != null && !current.getUser().getId().equals(userId)) {
                response.getConflicts().add("Customer " + item.getId() + ": unavailable"); continue;
            }
            if (current != null && current.isDeleted() && !item.isDeleted()) {
                response.getConflicts().add("Customer " + item.getId() + ": deleted on server"); continue;
            }
            if (current == null) {
                if (item.getBaseVersion() != null) { response.getConflicts().add("Customer " + item.getId() + ": missing"); continue; }
                current = new Customer(item.getId(), user, item.getName().trim(), item.getContactInformation());
            } else if (!Objects.equals(item.getBaseVersion(), current.getVersion())) {
                if (Objects.equals(current.getName(), item.getName()) && Objects.equals(current.getContactInformation(), item.getContactInformation()) && current.isDeleted() == item.isDeleted()) {
                    response.getSyncedCustomerIds().add(item.getId()); response.getCustomerVersions().put(item.getId(), current.getVersion()); continue;
                }
                response.getConflicts().add("Customer " + item.getId() + ": newer server version"); continue;
            }
            current.setName(item.getName().trim()); current.setContactInformation(item.getContactInformation()); current.setDeleted(item.isDeleted());
            if (item.isDeleted()) for (var site : sites.findByCustomerId(current.getId())) {
                site.setDeleted(true); site.setUpdatedAt(Instant.now());
                for (var note : notes.findBySiteId(site.getId())) { note.setDeleted(true); note.setUpdatedAt(Instant.now()); }
            }
            customers.saveAndFlush(current); response.getSyncedCustomerIds().add(item.getId()); response.getCustomerVersions().put(item.getId(), current.getVersion());
        }
        for (var item : request.getSites()) {
            var parent = customers.findByIdAndUserId(item.getCustomerId(), userId).orElse(null);
            var current = sites.findById(item.getId()).orElse(null);
            if (parent == null || (!item.isDeleted() && parent.isDeleted()) || (current != null && !current.getCustomer().getUser().getId().equals(userId))) {
                response.getConflicts().add("Site " + item.getId() + ": unavailable parent or record"); continue;
            }
            if (current != null && current.isDeleted() && !item.isDeleted()) {
                response.getConflicts().add("Site " + item.getId() + ": deleted on server"); continue;
            }
            if (current == null) {
                if (item.getBaseVersion() != null) { response.getConflicts().add("Site " + item.getId() + ": missing"); continue; }
                current = new Site(item.getId(), parent, item.getSiteName().trim(), item.getAddress());
            } else if (!Objects.equals(item.getBaseVersion(), current.getVersion())) {
                if (Objects.equals(current.getSiteName(), item.getSiteName()) && Objects.equals(current.getAddress(), item.getAddress()) && current.getCustomer().getId().equals(item.getCustomerId()) && current.isDeleted() == item.isDeleted()) {
                    response.getSyncedSiteIds().add(item.getId()); response.getSiteVersions().put(item.getId(), current.getVersion()); continue;
                }
                response.getConflicts().add("Site " + item.getId() + ": newer server version"); continue;
            }
            current.setCustomer(parent); current.setSiteName(item.getSiteName().trim()); current.setAddress(item.getAddress()); current.setDeleted(item.isDeleted());
            if (item.isDeleted()) for (var note : notes.findBySiteId(current.getId())) { note.setDeleted(true); note.setUpdatedAt(Instant.now()); }
            sites.saveAndFlush(current); response.getSyncedSiteIds().add(item.getId()); response.getSiteVersions().put(item.getId(), current.getVersion());
        }
        for (var item : request.getNotes()) {
            var parent = sites.findByIdAndCustomerUserId(item.getSiteId(), userId).orElse(null);
            var current = notes.findById(item.getId()).orElse(null);
            if (parent == null || (!item.isDeleted() && (parent.isDeleted() || parent.getCustomer().isDeleted())) || (current != null && !current.getSite().getCustomer().getUser().getId().equals(userId))) {
                response.getConflicts().add("Note " + item.getId() + ": unavailable parent or record"); continue;
            }
            Instant date = item.getDateTime() == null ? null : Instant.ofEpochMilli(item.getDateTime());
            if (current != null && current.isDeleted() && !item.isDeleted()) {
                response.getConflicts().add("Note " + item.getId() + ": deleted on server"); continue;
            }
            if (current == null) {
                if (item.getBaseVersion() != null) { response.getConflicts().add("Note " + item.getId() + ": missing"); continue; }
                current = new FieldNote(item.getId(), parent, item.getTitle().trim(), item.getDescription(), item.getLocation(), date == null ? Instant.now() : date, item.getStatus(), item.getPhoto());
            } else if (!Objects.equals(item.getBaseVersion(), current.getVersion())) {
                if (Objects.equals(current.getTitle(), item.getTitle()) && Objects.equals(current.getDescription(), item.getDescription()) && Objects.equals(current.getLocation(), item.getLocation()) && Objects.equals(current.getPhoto(), item.getPhoto()) && Objects.equals(current.getStatus(), item.getStatus()) && current.getSite().getId().equals(item.getSiteId()) && (date == null || current.getDateTime().toEpochMilli() == date.toEpochMilli()) && current.isDeleted() == item.isDeleted()) {
                    response.getSyncedNoteIds().add(item.getId()); response.getNoteVersions().put(item.getId(), current.getVersion()); continue;
                }
                response.getConflicts().add("Note " + item.getId() + ": newer server version"); continue;
            }
            current.setSite(parent); current.setTitle(item.getTitle().trim()); current.setDescription(item.getDescription()); current.setLocation(item.getLocation());
            if (date != null) current.setDateTime(date);
            current.setStatus(item.getStatus()); current.setPhoto(item.getPhoto()); current.setDeleted(item.isDeleted());
            notes.saveAndFlush(current); response.getSyncedNoteIds().add(item.getId()); response.getNoteVersions().put(item.getId(), current.getVersion());
        }
        return response;
    }
    // Full reconciliation avoids cursor gaps from concurrent transactions and includes tombstones.
    @Transactional(readOnly = true)
    public SyncPullResponse pullSync(Long userId, Instant since) {
        var response = new SyncPullResponse();
        response.setCustomers(customers.findByUserIdAndUpdatedAtAfter(userId, Instant.EPOCH).stream().map(CustomerDto::new).toList());
        response.setSites(sites.findByCustomerUserIdAndUpdatedAtAfter(userId, Instant.EPOCH).stream().map(SiteDto::new).toList());
        response.setNotes(notes.findBySiteCustomerUserIdAndUpdatedAtAfter(userId, Instant.EPOCH).stream().map(FieldNoteDto::new).toList());
        return response;
    }
}
