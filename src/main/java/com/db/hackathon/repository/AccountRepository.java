package com.db.hackathon.repository;

import com.db.hackathon.model.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface AccountRepository extends JpaRepository<UserAccount, UUID> {
    Optional<UserAccount> findByPhoneNumber(String phoneNumber);
}
