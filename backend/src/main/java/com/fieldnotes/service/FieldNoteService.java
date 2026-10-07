package com.fieldnotes.service;

import com.fieldnotes.dto.note.FieldNoteDto;
import com.fieldnotes.dto.note.FieldNoteRequest;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.model.FieldNote;
import com.fieldnotes.model.Site;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FieldNoteService {

    private final FieldNoteRepository fieldNoteRepository;
    private final SiteRepository siteRepository;

    public FieldNoteService(FieldNoteRepository fieldNoteRepository, SiteRepository siteRepository) {
        this.fieldNoteRepository = fieldNoteRepository;
        this.siteRepository = siteRepository;
    }

    @Transactional
    public FieldNoteDto createNote(Long userId, FieldNoteRequest request) {
        Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalse(request.getSiteId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found or not owned by user: " + request.getSiteId()));

        String noteId = (request.getId() != null && !request.getId().isBlank())
                ? request.getId()
                : UUID.randomUUID().toString();

        FieldNote note = new FieldNote(
                noteId,
                site,
                request.getTitle().trim(),
                request.getDescription(),
                request.getLocation(),
                request.getDateTime() != null ? request.getDateTime() : Instant.now(),
                request.getStatus(),
                request.getPhoto()
        );

        note = fieldNoteRepository.save(note);
        return new FieldNoteDto(note);
    }

    @Transactional(readOnly = true)
    public List<FieldNoteDto> getNotes(Long userId, String query, String siteId, String status) {
        List<FieldNote> notes = fieldNoteRepository.searchAndFilter(
                userId,
                (query != null && !query.isBlank()) ? query.trim() : null,
                (siteId != null && !siteId.isBlank()) ? siteId : null,
                (status != null && !status.isBlank()) ? status : null
        );

        return notes.stream().map(FieldNoteDto::new).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public FieldNoteDto getNoteById(Long userId, String noteId) {
        FieldNote note = fieldNoteRepository.findByIdAndSiteCustomerUserIdAndDeletedFalse(noteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found: " + noteId));
        return new FieldNoteDto(note);
    }

    @Transactional
    public FieldNoteDto updateNote(Long userId, String noteId, FieldNoteRequest request) {
        FieldNote note = fieldNoteRepository.findByIdAndSiteCustomerUserIdAndDeletedFalse(noteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found: " + noteId));

        if (request.getSiteId() != null && !request.getSiteId().equals(note.getSite().getId())) {
            Site site = siteRepository.findByIdAndCustomerUserIdAndDeletedFalse(request.getSiteId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Site not found or not owned by user: " + request.getSiteId()));
            note.setSite(site);
        }

        note.setTitle(request.getTitle().trim());
        note.setDescription(request.getDescription());
        note.setLocation(request.getLocation());
        if (request.getDateTime() != null) {
            note.setDateTime(request.getDateTime());
        }
        note.setStatus(request.getStatus());
        if (request.getPhoto() != null) {
            note.setPhoto(request.getPhoto());
        }
        note.setUpdatedAt(Instant.now());

        note = fieldNoteRepository.save(note);
        return new FieldNoteDto(note);
    }

    @Transactional
    public void deleteNote(Long userId, String noteId) {
        FieldNote note = fieldNoteRepository.findByIdAndSiteCustomerUserIdAndDeletedFalse(noteId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found: " + noteId));

        note.setDeleted(true);
        note.setUpdatedAt(Instant.now());
        fieldNoteRepository.save(note);
    }
}
