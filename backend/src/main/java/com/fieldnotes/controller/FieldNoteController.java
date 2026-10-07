package com.fieldnotes.controller;

import com.fieldnotes.dto.note.FieldNoteDto;
import com.fieldnotes.dto.note.FieldNoteRequest;
import com.fieldnotes.security.UserPrincipal;
import com.fieldnotes.service.FieldNoteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notes")
public class FieldNoteController {

    private final FieldNoteService fieldNoteService;

    public FieldNoteController(FieldNoteService fieldNoteService) {
        this.fieldNoteService = fieldNoteService;
    }

    @PostMapping
    public ResponseEntity<FieldNoteDto> createNote(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody FieldNoteRequest request
    ) {
        FieldNoteDto note = fieldNoteService.createNote(currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(note);
    }

    @GetMapping
    public ResponseEntity<List<FieldNoteDto>> getNotes(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "siteId", required = false) String siteId,
            @RequestParam(value = "status", required = false) String status
    ) {
        List<FieldNoteDto> notes = fieldNoteService.getNotes(currentUser.getId(), query, siteId, status);
        return ResponseEntity.ok(notes);
    }

    @GetMapping("/{id}")
    public ResponseEntity<FieldNoteDto> getNoteById(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String noteId
    ) {
        FieldNoteDto note = fieldNoteService.getNoteById(currentUser.getId(), noteId);
        return ResponseEntity.ok(note);
    }

    @PutMapping("/{id}")
    public ResponseEntity<FieldNoteDto> updateNote(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String noteId,
            @Valid @RequestBody FieldNoteRequest request
    ) {
        FieldNoteDto note = fieldNoteService.updateNote(currentUser.getId(), noteId, request);
        return ResponseEntity.ok(note);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNote(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable("id") String noteId
    ) {
        fieldNoteService.deleteNote(currentUser.getId(), noteId);
        return ResponseEntity.noContent().build();
    }
}
