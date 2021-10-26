# Imo Messaging

## Context

We do not currently send any notifications to patients in Bangladesh. As part of our ongoing efforts to increase patient return rates, we would like to start sending patients text messages, much like we do in India. SMS messages are so widely abused by spammers in India and Bangladesh that we expect most patients to ignore SMS messages. In India, we've addressed that concern by integrating with WhatsApp. In Bangladesh, Imo is more popular than WhatsApp, so we would like to be able to send notifications to Bangladeshi patients via Imo.

## Decision

Imo has recently created a partner API at our request. We will use that API in Bangladesh to send appointment reminder notifications to patients. We will first attempt to send the notification via Imo, then fall back to SMS via Twilio. This mirrors the approach we use in India of first sending via WhatsApp and falling back to SMS.

We will initially start sending notifications via an A/B test to determine the most effective message types. Once we've established the most effective messaging strategy, we will use that messaging for all appointments moving forward.

## Approach

The Imo API first requires patients to opt in to receiving notifications from the Simple Imo account. We will create a new job that will send invitations to all patients with mobile phone numbers. We will store the invitation result in the patient's ImoAuthorization model, along with a `last_invited_at` timestamp. We will include a callback url with the invitation request, and Imo will inform us once the patient has accepted the invitation, at which point we will update their ImoAuthorization status to "subscribed".

This invitations job will be scheduled as a cron. It will pick up any newly registered patients and send them invitations. We will also configure the job to periodically re-invite any patients who were previously invited but did not accept our invitation or did not have an Imo account.

Imo will be the preferred means of sending notifications for patients whose ImoAuthorization status is "subscribed". When we send a notification, Imo gives us a response status and a unique post_id that we will store in the Communication's ImoDeliveryDetail. If the patient views the message, Imo sends us a callback with the post_id, which we use to look up and update the ImoDeliveryDetail.

## Imo Architecture

We have two Imo API accounts: a test account and our real account. Both accounts are on Imo's production server and both have the ability to send real notifications to users' phones. The differences are that our test account is highly rate limited and we don't have the ability to customize it with our logo and copy. We can modify our production account through their web portal, and we should be able to send 15-20 thousand requests (invitations and notifications) per second.

## Testing

Because our test account is capable of sending real messages, we should only set the API keys for lower environments when we're actively testing and have turned off any code that could accidentally send Imo notifications.

Imo exists as two separate apps run by completely different companies. "Imo HD" is the US version of the app, and "Imo" is the international version. As a result of that split, the Imo app we're using is not capable of sending notifications to US phone numbers. For testing purposes, they have a special country code `+999` for US numbers. To use a US number, we must first request that the Imo team whitelist it. Then we can send notifications to US phone numbers through our test account. If your US number is `111-222-3333`, you would need to send the Imo request to the phone number `+9991112223333`. That is also the number you will need to enter into the Imo app when prompted for your phone number.

US based users will not have access to the international version of the Imo app through the Google Play Store and will have to download the app from http://imo.im. To install the APK without the store, you will first have to enable the ability to install from unknown sources and elect to trust the download source. See this video tutorial for help: https://www.youtube.com/watch?v=4X5hOvH-fbs

## Consequences

The Imo API documentation is not exhaustive, and we've only coded for responses we've been able to find through manual testing. There may be additional response types we haven't accounted for. Any unexpected responses will raise errors. We will need to monitor those errors and make changes accordingly.

There are some small differences in data schema between ImoDeliveryDetail and TwilioSmsDeliveryDetail that may need to be accounted for in A/B framework queries.