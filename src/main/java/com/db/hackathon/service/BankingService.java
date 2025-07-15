package com.db.hackathon.service;

import com.db.hackathon.controller.WhatsappBankingController;
import com.db.hackathon.repository.AccountRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

@Service
public class BankingService {

    @Autowired
    private AccountRepository repo;

    public String handleMessage(String phoneNumber, String body) {
        body = body.toLowerCase();

        if (body.contains("balance")) {
            return checkBalance(phoneNumber);
        } else if (body.contains("create fd")) {
            return createFD(phoneNumber);
        } else {
            return "Sorry, I didn't understand. You can say 'Check balance' or 'Create FD'.";
        }
    }

    private String checkBalance(String phone) {
        var user = repo.findByPhoneNumber(phone).orElse(null);
        return user == null ? "Account not found" : "Your balance is ₹" + user.getBalance();
    }

    private String createFD(String phone) {
        var user = repo.findByPhoneNumber(phone).orElse(null);
        if (user == null) return "Account not found";

        if (user.getBalance() < 1000) {
            return "Insufficient balance to create FD";
        }

        user.setBalance(user.getBalance() - 1000);
        repo.save(user);
        return "FD of ₹1000 created successfully!";
    }

    @PostMapping
    public ResponseEntity<Void> receiveMessage(@RequestParam Map<String, Object> payload, WhatsappBankingController whatsappBankingController) {
        String from = (String) payload.get("From");
        String body = (String) payload.get("Body");

        String response = handleMessage(from.replace("whatsapp:", ""), body);
        whatsappBankingController.sender.sendMessage(from, response);

        return ResponseEntity.ok().build();
    }
}
