package com.db.hackathon.util;

import com.twilio.Twilio;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

@Component
public class WhatsAppSender {

    @Value("${twilio.account.sid}")
    private String accountSid;

    @Value("${twilio.auth.token}")
    private String authToken;

    @Value("${twilio.from}")
    private String fromNumber;

    public void sendMessage(String to, String body) {
        RestTemplate restTemplate = new RestTemplate();

        String url = "https://api.twilio.com/2010-04-01/Accounts/" + accountSid + "/Messages.json";

        HttpHeaders headers = new HttpHeaders();
        headers.setBasicAuth(accountSid, authToken);
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> map = new LinkedMultiValueMap<>();
        map.add("From", fromNumber);
        map.add("To", to);
        map.add("Body", body);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(map, headers);
        restTemplate.postForEntity(url, request, String.class);
    }

    @PostConstruct
    public void twilioInit(){
        Twilio.init(accountSid, authToken);
        System.out.println("Twilio initialized successfully");
    }
}
