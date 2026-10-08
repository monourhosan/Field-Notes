package com.fieldnotes;

import com.fieldnotes.dto.customer.CustomerDto;
import com.fieldnotes.dto.customer.CustomerRequest;
import com.fieldnotes.dto.site.SiteDto;
import com.fieldnotes.dto.site.SiteRequest;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.model.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.SiteRepository;
import com.fieldnotes.repository.UserRepository;
import com.fieldnotes.service.CustomerService;
import com.fieldnotes.service.SiteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class CustomerAndSiteServiceTest {

    @Autowired
    private CustomerService customerService;

    @Autowired
    private SiteService siteService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private SiteRepository siteRepository;

    private User userA;
    private User userB;

    @BeforeEach
    void setUp() {
        siteRepository.deleteAll();
        customerRepository.deleteAll();
        userRepository.deleteAll();

        userA = userRepository.save(new User("workerA", "a@test.com", "pass"));
        userB = userRepository.save(new User("workerB", "b@test.com", "pass"));
    }

    @Test
    void testCustomerCrudAndIsolation() {
        // User A creates customer
        CustomerRequest req = new CustomerRequest(null, "Acme Corp", "acme@contact.com");
        CustomerDto created = customerService.createCustomer(userA.getId(), req);

        assertNotNull(created.getId());
        assertEquals("Acme Corp", created.getName());

        // User A can view it
        List<CustomerDto> listA = customerService.getCustomers(userA.getId());
        assertEquals(1, listA.size());

        // User B CANNOT view or access User A's customer (data isolation requirement)
        List<CustomerDto> listB = customerService.getCustomers(userB.getId());
        assertEquals(0, listB.size());
        assertThrows(ResourceNotFoundException.class, () -> customerService.getCustomerById(userB.getId(), created.getId()));

        // User A updates customer
        CustomerRequest updateReq = new CustomerRequest(null, "Acme International", "hq@acme.com");
        updateReq.setVersion(created.getVersion());
        CustomerDto updated = customerService.updateCustomer(userA.getId(), created.getId(), updateReq);
        assertEquals("Acme International", updated.getName());

        // User A deletes customer (soft delete)
        customerService.deleteCustomer(userA.getId(), created.getId());
        assertEquals(0, customerService.getCustomers(userA.getId()).size());
    }

    @Test
    void testSiteCrudAndRelationship() {
        CustomerRequest cReq = new CustomerRequest(null, "Beta Tech", "beta@test.com");
        CustomerDto customer = customerService.createCustomer(userA.getId(), cReq);

        SiteRequest sReq = new SiteRequest(null, customer.getId(), "North Plant", "123 Industrial Way");
        SiteDto site = siteService.createSite(userA.getId(), sReq);

        assertNotNull(site.getId());
        assertEquals("North Plant", site.getSiteName());
        assertEquals(customer.getId(), site.getCustomerId());

        // User B cannot view or add sites under User A's customer
        assertThrows(ResourceNotFoundException.class, () -> siteService.createSite(userB.getId(), sReq));
        assertEquals(0, siteService.getSites(userB.getId(), null).size());
    }
}
