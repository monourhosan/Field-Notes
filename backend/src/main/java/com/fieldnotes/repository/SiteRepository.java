package com.fieldnotes.repository;

import com.fieldnotes.model.Site;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface SiteRepository extends JpaRepository<Site, String> {
    List<Site> findByCustomerUserIdAndDeletedFalse(Long userId);
    List<Site> findByCustomerIdAndCustomerUserIdAndDeletedFalse(String customerId, Long userId);
    Optional<Site> findByIdAndCustomerUserId(String id, Long userId);
    Optional<Site> findByIdAndCustomerUserIdAndDeletedFalse(String id, Long userId);
    List<Site> findByCustomerUserIdAndUpdatedAtAfter(Long userId, Instant updatedAt);
}
