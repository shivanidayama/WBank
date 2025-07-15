package com.db.hackathon.controller;

import com.db.hackathon.service.BankingService;
import com.db.hackathon.util.WhatsAppSender;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/webhook")
public class WhatsappBankingController {

    @Autowired
    private BankingService bankingService;

    @Autowired
    private WhatsAppSender sender;

    @PostMapping("sendMessage")
    public String sendMessage(){
        String userNumber = "whatsapp:+918149475268";
        String fromNumber = "whatsapp:+14155238886";
        String messageBody = "Your appointment is coming up on Aug 20 at 4 PM. \n\n" +
                "Please reply with:\n" +
                "1 - Confirm\n" +
                "2 - Cancel";

        Message message = Message.creator(new PhoneNumber(userNumber), new PhoneNumber(fromNumber), messageBody).create();
        return "Message sent with SID: " + message.getSid();
    }
}
