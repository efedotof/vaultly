package com.efedotov.vaultly.service;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.security.CustomUserDetails;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserDetailsServiceImplTest {

    @Mock
    UserRepository userRepository;
    @InjectMocks
    UserDetailsServiceImpl service;

    @Test
    void loadUserByUsername_found_returnsCustomUserDetails() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).username("alice").isActive(true).build();
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));

        UserDetails details = service.loadUserByUsername("alice");

        assertThat(details).isInstanceOf(CustomUserDetails.class);
        assertThat(details.getUsername()).isEqualTo("alice");
        assertThat(((CustomUserDetails) details).getUserId()).isEqualTo(id);
    }

    @Test
    void loadUserByUsername_notFound_throws() {
        when(userRepository.findByUsername("nobody")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.loadUserByUsername("nobody"))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessageContaining("User not found");
    }

    @Test
    void loadUserById_found_returnsCustomUserDetails() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).username("alice").isActive(true).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(user));

        UserDetails details = service.loadUserById(id);

        assertThat(details).isInstanceOf(CustomUserDetails.class);
        assertThat(details.getUsername()).isEqualTo("alice");
        assertThat(((CustomUserDetails) details).getUserId()).isEqualTo(id);
    }

    @Test
    void loadUserById_notFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.loadUserById(id))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessageContaining("User not found by id");
    }
}