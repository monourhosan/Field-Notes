package com.fieldnotes.repository;

import com.fieldnotes.model.Site;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface SiteRepository extends JpaRepository<Site, String> {
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
    List<Site> findByCustomerId(String customerId);
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
    List<Site> findByCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(Long userId);
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
    List<Site> findByCustomerIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(String customerId, Long userId);
    Optional<Site> findByIdAndCustomerUserId(String id, Long userId);
    Optional<Site> findByIdAndCustomerUserIdAndDeletedFalseAndCustomerDeletedFalse(String id, Long userId);
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
    List<Site> findByCustomerUserIdAndUpdatedAtAfter(Long userId, Instant updatedAt);
}
