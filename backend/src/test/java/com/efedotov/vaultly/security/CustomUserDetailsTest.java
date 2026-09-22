package com.efedotov.vaultly.security;

import com.efedotov.vaultly.model.Role;
import com.efedotov.vaultly.model.User;
import org.junit.jupiter.api.Test;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

class CustomUserDetailsTest {

    private User user() {
        return User.builder()
                .id(UUID.randomUUID())
                .username("alice")
                .passwordHash("hash")
                .isActive(true)
                .roles(new HashSet<>())
                .build();
    }

    private Role role(String name) {
        Role r = new Role();
        r.setRoleName(name);
        return r;
    }

    @Test
    void getUserId_returnsId() {
        User u = user();
        assertThat(new CustomUserDetails(u).getUserId()).isEqualTo(u.getId());
    }

    @Test
    void getUsername_returnsUsername() {
        assertThat(new CustomUserDetails(user()).getUsername()).isEqualTo("alice");
    }

    @Test
    void getPassword_returnsHash() {
        assertThat(new CustomUserDetails(user()).getPassword()).isEqualTo("hash");
    }

    @Test
    void getAuthorities_emptyRoles_returnsEmptyList() {
        assertThat(new CustomUserDetails(user()).getAuthorities()).isEmpty();
    }

    @Test
    void getAuthorities_nullRoles_returnsEmptyList() {
        User u = User.builder().id(UUID.randomUUID()).username("alice")
                .passwordHash("hash").roles(null).build();
        assertThat(new CustomUserDetails(u).getAuthorities()).isEmpty();
    }

    @Test
    void getAuthorities_rolesAreUppercasedWithPrefix() {
        User u = user();
        u.setRoles(Set.of(role("user"), role("admin")));

        Set<String> authorities = new CustomUserDetails(u).getAuthorities().stream()
                .map(a -> a.getAuthority())
                .collect(Collectors.toSet());

        assertThat(authorities).containsExactlyInAnyOrder("ROLE_USER", "ROLE_ADMIN");
    }

    @Test
    void getAuthorities_lowercaseRoleName_uppercased() {
        User u = user();
        u.setRoles(Set.of(role("moderator")));

        List<String> authorities = new CustomUserDetails(u).getAuthorities().stream()
                .map(a -> a.getAuthority())
                .toList();

        assertThat(authorities).containsExactly("ROLE_MODERATOR");
        assertThat(authorities.get(0)).isInstanceOf(String.class);
    }

    @Test
    void isEnabled_trueForActiveUser() {
        User u = user();
        u.setIsActive(true);
        assertThat(new CustomUserDetails(u).isEnabled()).isTrue();
    }

    @Test
    void isEnabled_falseForInactiveUser() {
        User u = user();
        u.setIsActive(false);
        assertThat(new CustomUserDetails(u).isEnabled()).isFalse();
    }

    @Test
    void isEnabled_falseForNullIsActive() {
        User u = user();
        u.setIsActive(null);
        assertThat(new CustomUserDetails(u).isEnabled()).isFalse();
    }

    @Test
    void accountFlags_alwaysTrue() {
        CustomUserDetails details = new CustomUserDetails(user());
        assertThat(details.isAccountNonExpired()).isTrue();
        assertThat(details.isAccountNonLocked()).isTrue();
        assertThat(details.isCredentialsNonExpired()).isTrue();
    }
}