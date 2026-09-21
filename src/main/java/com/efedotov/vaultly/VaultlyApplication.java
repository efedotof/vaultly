package com.efedotov.vaultly;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class VaultlyApplication {

    public static void main(String[] args) {
        SpringApplication.run(VaultlyApplication.class, args);
    }
}