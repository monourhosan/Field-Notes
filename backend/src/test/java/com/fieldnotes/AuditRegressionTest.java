package com.fieldnotes;

import com.fieldnotes.dto.customer.*;
import com.fieldnotes.dto.site.*;
import com.fieldnotes.dto.note.*;
import com.fieldnotes.dto.sync.*;
import com.fieldnotes.exception.*;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.*;
import com.fieldnotes.service.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import com.fieldnotes.security.UserPrincipal;

@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional
class AuditRegressionTest {
    @Autowired UserRepository users;
    @Autowired CustomerRepository customers;
    @Autowired SiteRepository sites;
    @Autowired FieldNoteRepository notes;
    @Autowired CustomerService customerService;
    @Autowired SiteService siteService;
    @Autowired FieldNoteService noteService;
    @Autowired SyncService sync;
    @Autowired MockMvc mvc;
    User owner, other;
    CustomerDto customer;
    SiteDto site;
    @BeforeEach void setup() {
        String suffix = UUID.randomUUID().toString();
        owner = users.saveAndFlush(new User("owner"+suffix, suffix+"@owner.com", "password"));
        other = users.saveAndFlush(new User("other"+suffix, suffix+"@other.com", "password"));
        customer = customerService.createCustomer(owner.getId(), new CustomerRequest(null,"Original",null));
        site = siteService.createSite(owner.getId(), new SiteRequest(null,customer.getId(),"Site",null));
    }
    SyncPushRequest.CustomerSyncItem item(String id, String name, Long version) {
        var item = new SyncPushRequest.CustomerSyncItem(); item.setId(id); item.setName(name); item.setBaseVersion(version);
        item.setUpdatedAt(Long.MAX_VALUE); return item;
    }
    @Test void suppliedIdsCannotOverwriteAnotherAccount() {
        assertThrows(ConflictException.class, () -> customerService.createCustomer(other.getId(),new CustomerRequest(customer.getId(),"Attack",null)));
        var push = new SyncPushRequest(); push.getCustomers().add(item(customer.getId(),"Attack",customer.getVersion()));
        var response = sync.pushSync(other.getId(),push);
        assertTrue(response.getSyncedCustomerIds().isEmpty()); assertEquals(1,response.getConflicts().size());
        assertEquals("Original",customers.findById(customer.getId()).orElseThrow().getName());
        assertThrows(ResourceNotFoundException.class, () -> siteService.getSiteById(other.getId(),site.getId()));
    }
    @Test void staleDeviceClockCannotOverwriteAndIdenticalRetryIsAcknowledged() {
        var request = new CustomerRequest(null,"Server edit",null); request.setVersion(customer.getVersion());
        var edited = customerService.updateCustomer(owner.getId(),customer.getId(),request);
        assertTrue(edited.getVersion() > customer.getVersion());
        var push = new SyncPushRequest(); push.getCustomers().add(item(customer.getId(),"Offline edit",customer.getVersion()));
        assertEquals(1,sync.pushSync(owner.getId(),push).getConflicts().size());
        assertEquals("Server edit",customers.findById(customer.getId()).orElseThrow().getName());
        push.getCustomers().clear(); push.getCustomers().add(item(customer.getId(),"Server edit",customer.getVersion()));
        var retry = sync.pushSync(owner.getId(),push);
        assertEquals(1,retry.getSyncedCustomerIds().size());
        assertEquals(edited.getVersion(),retry.getCustomerVersions().get(customer.getId()));
        assertThrows(ConflictException.class, () -> customerService.updateCustomer(owner.getId(),customer.getId(),request));
    }
    @Test void missingParentsAreRejectedRatherThanAcknowledged() {
        var push = new SyncPushRequest(); var item = new SyncPushRequest.SiteSyncItem();
        item.setId(UUID.randomUUID().toString()); item.setCustomerId("missing"); item.setSiteName("Site"); push.getSites().add(item);
        var response = sync.pushSync(owner.getId(),push);
        assertTrue(response.getSyncedSiteIds().isEmpty()); assertEquals(1,response.getConflicts().size());
        assertFalse(sites.existsById(item.getId()));
    }
    @Test void parentDeletionCascadesAndTombstonesAreReconciledDespiteFutureCursor() {
        var note = noteService.createNote(owner.getId(),new FieldNoteRequest(null,site.getId(),"Note",null,null,Instant.now(),"DRAFT",null));
        customerService.deleteCustomer(owner.getId(),customer.getId());
        assertTrue(sites.findById(site.getId()).orElseThrow().isDeleted());
        assertTrue(notes.findById(note.getId()).orElseThrow().isDeleted());
        assertTrue(noteService.getNotes(owner.getId(),null,null,null).isEmpty());
        assertThrows(ResourceNotFoundException.class, () -> noteService.getNoteById(owner.getId(),note.getId()));
        var pull = sync.pullSync(owner.getId(),Instant.now().plusSeconds(3600));
        assertTrue(pull.getCustomers().stream().anyMatch(c -> c.getId().equals(customer.getId()) && c.isDeleted()));
        assertTrue(pull.getNotes().stream().anyMatch(n -> n.getId().equals(note.getId()) && n.isDeleted()));
    }
    @Test void photoCanBeRemovedAndNotesCanMoveOnlyToOwnedSites() {
        var note = noteService.createNote(owner.getId(),new FieldNoteRequest(null,site.getId(),"Note",null,null,Instant.now(),"DRAFT","photo"));
        var request = new FieldNoteRequest(null,site.getId(),"Note",null,null,note.getDateTime(),"DRAFT",null); request.setVersion(note.getVersion());
        assertNull(noteService.updateNote(owner.getId(),note.getId(),request).getPhoto());
        var outsider = customerService.createCustomer(other.getId(),new CustomerRequest(null,"Other",null));
        var otherSite = siteService.createSite(other.getId(),new SiteRequest(null,outsider.getId(),"Other site",null));
        request.setSiteId(otherSite.getId());
        assertThrows(ResourceNotFoundException.class, () -> noteService.updateNote(owner.getId(),note.getId(),request));
    }
    @Test void expiredSignedTokensAreRejected() throws Exception {
        var provider = new com.fieldnotes.security.JwtTokenProvider("test-only-signing-key-not-for-production-0000000000000000000000000",-10000);
        var authentication = new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(UserPrincipal.create(owner),null,java.util.List.of());
        mvc.perform(get("/api/customers").header("Authorization","Bearer "+provider.generateToken(authentication))).andExpect(status().isUnauthorized());
    }
    @Test void conditionalPullInvalidatesOnOwnedEditsAndIgnoresOtherAccounts() throws Exception {
        String tag = mvc.perform(get("/api/sync/pull").with(user(UserPrincipal.create(owner))))
            .andExpect(status().isOk()).andReturn().getResponse().getHeader("ETag");
        assertNotNull(tag);
        mvc.perform(get("/api/sync/pull").with(user(UserPrincipal.create(owner))).header("If-None-Match",tag))
            .andExpect(status().isNotModified()).andExpect(content().string(""));
        customerService.createCustomer(other.getId(),new CustomerRequest(null,"Other",null));
        mvc.perform(get("/api/sync/pull").with(user(UserPrincipal.create(owner))).header("If-None-Match",tag))
            .andExpect(status().isNotModified());
        var edit = new CustomerRequest(null,"Changed",null); edit.setVersion(customer.getVersion());
        customerService.updateCustomer(owner.getId(),customer.getId(),edit);
        mvc.perform(get("/api/sync/pull").with(user(UserPrincipal.create(owner))).header("If-None-Match",tag))
            .andExpect(status().isOk());
    }
    @Test void loginRejectsOversizePasswordsAndRegistrationRejectsTrimmedShortNames() throws Exception {
        mvc.perform(post("/api/auth/login").contentType("application/json").content("{\"username\":\"missing\",\"password\":\""+"é".repeat(40)+"\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/register").contentType("application/json").content("{\"username\":\" x \",\"email\":\"short@example.com\",\"password\":\"password\"}"))
            .andExpect(status().isBadRequest());
    }
    @Test void authenticationAttemptsAreRateLimited() throws Exception {
        for (int i=0;i<21;i++) {
            final int expected = i<20 ? 401 : 429;
            mvc.perform(post("/api/auth/login").with(req -> {req.setRemoteAddr("198.51.100.9"); return req;}).contentType("application/json").content("{\"username\":\"missing\",\"password\":\"wrong\"}"))
                .andExpect(status().is(expected));
        }
    }
    @Test void requestValidatorsAcceptValidCrudFieldsAndRejectOversize() {
        try (var factory = jakarta.validation.Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            assertTrue(validator.validate(new CustomerRequest(null,"Valid",null)).isEmpty());
            assertTrue(validator.validate(new SiteRequest(null,customer.getId(),"Valid",null)).isEmpty());
            assertTrue(validator.validate(new FieldNoteRequest(null,site.getId(),"Valid",null,null,Instant.now(),"DRAFT",null)).isEmpty());
            assertFalse(validator.validate(new CustomerRequest(null,"x".repeat(256),null)).isEmpty());
            assertTrue(validator.validate(new FieldNoteRequest(null,site.getId(),"Future",null,null,Instant.parse("2040-01-02T03:04:05Z"),"DRAFT",null)).isEmpty());
            assertFalse(validator.validate(new FieldNoteRequest(null,site.getId(),"Too far",null,null,Instant.parse("+10000-01-01T00:00:00Z"),"DRAFT",null)).isEmpty());
        }
    }
    @Test void invalidQueryParametersAndUnknownRoutesUseClientErrors() throws Exception {
        mvc.perform(get("/api/sync/pull?since=invalid").with(user(UserPrincipal.create(owner)))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/unknown").with(user(UserPrincipal.create(owner)))).andExpect(status().isNotFound());
    }
    @Test void apiLimitsBodySizeBeforeParsing() throws Exception {
        mvc.perform(post("/api/customers").with(user(UserPrincipal.create(owner))).contentType("application/json").content("x".repeat(8*1024*1024+1))).andExpect(status().isPayloadTooLarge());
    }
    @Test void apiRejectsMissingInvalidTokensMalformedAndInvalidNestedPayloads() throws Exception {
        mvc.perform(post("/api/sync/push").with(user(UserPrincipal.create(owner))).contentType("application/json").content("{\"customers\":[null]}"))
            .andExpect(status().isBadRequest());
        mvc.perform(get("/api/customers")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/customers").header("Authorization","Bearer invalid")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/sync/push").with(user(UserPrincipal.create(owner))).contentType("application/json").content("{\"customers\":[{\"id\":\"x\",\"name\":\"\"}]}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/sync/push").with(user(UserPrincipal.create(owner))).contentType("application/json").content("{"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("{\"username\":\"missing\",\"password\":\"wrong\"}"))
            .andExpect(status().isUnauthorized());
    }
}
