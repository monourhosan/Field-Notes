package com.fieldnotes;

import com.fieldnotes.dto.auth.AuthResponse;
import com.fieldnotes.dto.auth.LoginRequest;
import com.fieldnotes.dto.auth.RegisterRequest;
import com.fieldnotes.exception.BadRequestException;
import com.fieldnotes.repository.UserRepository;
import com.fieldnotes.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class AuthServiceTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void testRegisterSuccess() {
        RegisterRequest request = new RegisterRequest("testworker", "worker@fieldnotes.com", "Password123!");
        AuthResponse response = authService.register(request);

        assertNotNull(response);
        assertNotNull(response.getToken());
        assertEquals("testworker", response.getUsername());
        assertEquals("worker@fieldnotes.com", response.getEmail());
        assertTrue(userRepository.existsByUsername("testworker"));
    }

    @Test
    void testRegisterDuplicateUsernameThrowsException() {
        RegisterRequest request1 = new RegisterRequest("samename", "worker1@fieldnotes.com", "Password123!");
        authService.register(request1);

        RegisterRequest request2 = new RegisterRequest("samename", "worker2@fieldnotes.com", "Password123!");
        assertThrows(BadRequestException.class, () -> authService.register(request2));
    }

    @Test
    void testLoginSuccess() {
        RegisterRequest reg = new RegisterRequest("loginuser", "login@fieldnotes.com", "SecretPass123");
        authService.register(reg);

        LoginRequest login = new LoginRequest("loginuser", "SecretPass123");
        AuthResponse response = authService.login(login);

        assertNotNull(response);
        assertNotNull(response.getToken());
        assertEquals("loginuser", response.getUsername());
    }
}
