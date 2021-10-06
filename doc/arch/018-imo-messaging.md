# Imo Messaging

## Context

We do not currently send any notifications to patients in Bangladesh. As part of our ongoing efforts to increase patient return rates, we would like to start sending patients text messages, much like we do in India. SMS messages are so widely abused by spammers in India and Bangladesh that we expect most patients to ignore SMS messages. In India, we've addressed that concern by integrating with WhatsApp. In Bangladesh, Imo is a more popular messaging platform than WhatsApp, so we would like to be able to send notifications to Bangladeshi patients via Imo.

## Decision

Imo has recently created a partner API at our request. We will use that API in Bangladesh to send appointment reminder notifications to patients. We will first attempt to send the notification via Imo, then fall back to SMS. This mirrors the approach we use in India of first sending via WhatsApp and falling back to SMS.

We will initially start sending notifications via an A/B test to determine the most effective message types. Once we've established the most effective messaging, we will use that messaging for all appointments moving forward.

## Approach

The Imo API first requires patients to opt-in to receiving notifications from the Simple Imo account. We will create a new job that will send invitations to all patients with mobile phone numbers. The result of each invitation will be stored in the patient's newly created ImoAuthorization model, along with a `last_invited_at` timestamp. The Imo invitation response will inform us if the patient does not have an Imo account and we will store that in the patient's ImoAuthorization. If the patient does have an account, we will record that they were invited. We will also include a callback url with the request, and Imo will inform us once the patient has accepted the invitation, at which point we will update their ImoAuthorization status to "subscribed".

This invitations job will be scheduled as a cron. This will pick up any newly registered patients and send them invitations. We will also configure the job to re-invite any unsubscribed patients who were last invited more than six months prior.


## Consequences



## Resources

Imo's API documentation:
https://docs.google.com/document/d/1zaTouxdfGg4IqrkCk59KAP905vwynON5Up2ckUax8Mg/edit
