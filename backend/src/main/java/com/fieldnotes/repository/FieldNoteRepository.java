package com.fieldnotes.repository;

import com.fieldnotes.model.FieldNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface FieldNoteRepository extends JpaRepository<FieldNote, String> {
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"site", "site.customer"})
    List<FieldNote> findBySiteId(String siteId);
    
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"site", "site.customer"})
    List<FieldNote> findBySiteCustomerUserIdAndDeletedFalse(Long userId);
    
    Optional<FieldNote> findByIdAndSiteCustomerUserId(String id, Long userId);
    
    Optional<FieldNote> findByIdAndSiteCustomerUserIdAndDeletedFalseAndSiteDeletedFalseAndSiteCustomerDeletedFalse(String id, Long userId);
    
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"site", "site.customer"})
    List<FieldNote> findBySiteCustomerUserIdAndUpdatedAtAfter(Long userId, Instant updatedAt);

    @Query("SELECT n FROM FieldNote n " +
           "JOIN n.site s " +
           "JOIN s.customer c " +
           "WHERE c.user.id = :userId " +
           "AND n.deleted = false AND s.deleted = false AND c.deleted = false " +
           "AND (:siteId IS NULL OR s.id = :siteId) " +
           "AND (:status IS NULL OR n.status = :status) " +
           "AND (:query IS NULL OR :query = '' OR " +
           "     LOWER(n.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "     LOWER(n.description) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "     LOWER(s.siteName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "     LOWER(c.name) LIKE LOWER(CONCAT('%', :query, '%')))")
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"site", "site.customer"})
    List<FieldNote> searchAndFilter(
            @Param("userId") Long userId,
            @Param("query") String query,
            @Param("siteId") String siteId,
            @Param("status") String status
    );
}
