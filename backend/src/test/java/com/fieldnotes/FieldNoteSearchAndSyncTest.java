package com.fieldnotes;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.customer.CustomerRequest;
import com.fieldnotes.dto.note.FieldNoteDto;
import com.fieldnotes.dto.note.FieldNoteRequest;
import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.dto.sync.SyncPullResponse;
import com.fieldnotes.dto.sync.SyncPushRequest;
import com.fieldnotes.dto.sync.SyncPushResponse;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import com.fieldnotes.repository.UserRepository;
import com.fieldnotes.service.CustomerService;
import com.fieldnotes.service.FieldNoteService;
import com.fieldnotes.service.SiteService;
import com.fieldnotes.service.SyncService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class FieldNoteSearchAndSyncTest {

    @Autowired
    private CustomerService customerService;

    @Autowired
    private SiteService siteService;

    @Autowired
    private FieldNoteService fieldNoteService;

    @Autowired
    private SyncService syncService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private SiteRepository siteRepository;

    @Autowired
    private FieldNoteRepository fieldNoteRepository;

    private User user;
    private CustomerDto customer;
    private SiteDto site;

    @BeforeEach
    void setUp() {
        fieldNoteRepository.deleteAll();
        siteRepository.deleteAll();
        customerRepository.deleteAll();
        userRepository.deleteAll();

        user = userRepository.save(new User("inspector", "inspector@fieldnotes.com", "pass"));
        customer = customerService.createCustomer(user.getId(), new CustomerRequest(null, "Global Energy", "energy@global.com"));
        site = siteService.createSite(user.getId(), new SiteRequest(null, customer.getId(), "Solar Farm A", "Desert Highway 4"));
    }

    @Test
    void testCreateSearchAndFilterNotes() {
        FieldNoteRequest noteReq1 = new FieldNoteRequest(
                null, site.getId(), "Inverter Inspection", "Checked electrical conduits and measured voltage",
                "34.05,-118.25", Instant.now(), "COMPLETED", "data:image/jpeg;base64,sample"
        );
        FieldNoteDto note1 = fieldNoteService.createNote(user.getId(), noteReq1);
        assertNotNull(note1.getId());
        assertEquals("Solar Farm A", note1.getSiteName());

        FieldNoteRequest noteReq2 = new FieldNoteRequest(
                null, site.getId(), "Transformer Maintenance", "Oil levels low, scheduled refill",
                "34.06,-118.26", Instant.now(), "IN_PROGRESS", null
        );
        fieldNoteService.createNote(user.getId(), noteReq2);

        // Search by title keyword
        List<FieldNoteDto> searchTitle = fieldNoteService.getNotes(user.getId(), "Inverter", null, null);
        assertEquals(1, searchTitle.size());
        assertEquals("Inverter Inspection", searchTitle.get(0).getTitle());

        // Search by description keyword
        List<FieldNoteDto> searchDesc = fieldNoteService.getNotes(user.getId(), "voltage", null, null);
        assertEquals(1, searchDesc.size());

        // Filter by status
        List<FieldNoteDto> filterCompleted = fieldNoteService.getNotes(user.getId(), null, null, "COMPLETED");
        assertEquals(1, filterCompleted.size());

        List<FieldNoteDto> filterInProgress = fieldNoteService.getNotes(user.getId(), null, null, "IN_PROGRESS");
        assertEquals(1, filterInProgress.size());
    }

    @Test
    void testOfflineSyncPushAndPull() {
        // Prepare offline created items
        String offlineCustId = UUID.randomUUID().toString();
        String offlineSiteId = UUID.randomUUID().toString();
        String offlineNoteId = UUID.randomUUID().toString();

        SyncPushRequest pushRequest = new SyncPushRequest();

        SyncPushRequest.CustomerSyncItem cItem = new SyncPushRequest.CustomerSyncItem();
        cItem.setId(offlineCustId);
        cItem.setName("Offline Client Ltd");
        cItem.setContactInformation("offline@client.com");
        cItem.setDeleted(false);
        cItem.setUpdatedAt(System.currentTimeMillis());
        pushRequest.getCustomers().add(cItem);

        SyncPushRequest.SiteSyncItem sItem = new SyncPushRequest.SiteSyncItem();
        sItem.setId(offlineSiteId);
        sItem.setCustomerId(offlineCustId);
        sItem.setSiteName("Substation 9");
        sItem.setAddress("Rural Road 9");
        sItem.setDeleted(false);
        sItem.setUpdatedAt(System.currentTimeMillis());
        pushRequest.getSites().add(sItem);

        SyncPushRequest.FieldNoteSyncItem nItem = new SyncPushRequest.FieldNoteSyncItem();
        nItem.setId(offlineNoteId);
        nItem.setSiteId(offlineSiteId);
        nItem.setTitle("Offline Field Check");
        nItem.setDescription("Recorded without connection");
        nItem.setLocation("40.71,-74.00");
        nItem.setDateTime(System.currentTimeMillis());
        nItem.setStatus("PENDING");
        nItem.setDeleted(false);
        nItem.setUpdatedAt(System.currentTimeMillis());
        pushRequest.getNotes().add(nItem);

        // Push sync
        SyncPushResponse pushResponse = syncService.pushSync(user.getId(), pushRequest);
        assertTrue(pushResponse.getSyncedCustomerIds().contains(offlineCustId));
        assertTrue(pushResponse.getSyncedSiteIds().contains(offlineSiteId));
        assertTrue(pushResponse.getSyncedNoteIds().contains(offlineNoteId));

        // Pull sync
        SyncPullResponse pullResponse = syncService.pullSync(user.getId(), Instant.EPOCH);
        assertTrue(pullResponse.getCustomers().stream().anyMatch(c -> c.getId().equals(offlineCustId)));
        assertTrue(pullResponse.getSites().stream().anyMatch(s -> s.getId().equals(offlineSiteId)));
        assertTrue(pullResponse.getNotes().stream().anyMatch(n -> n.getId().equals(offlineNoteId)));
    }
}
