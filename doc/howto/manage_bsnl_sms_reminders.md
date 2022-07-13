# Sending reminder SMS via BSNL

We use BSNL's SMS service [bulksms.bsnl.in](bulksms.bsnl.in) to send reminder messages in India.
Sending SMSes in India requires us to comply with TRAI regulations, for which we need to get our messages approved through [BSNL's DLT portal](https://www.ucc-bsnl.co.in).
This is a how-to on using both these services.

### Maintaining balance on bulk SMS

Since bulksms is a prepaid service, SMSes need to be manually procured every once in a while.
This is an ongoing manual chore. Someone needs to buy an "SMS pack" in advance and make sure there's balance in the account.

How to buy
  - Sign in to the [bulksms portal](bulksms.bsnl.in). The OTP goes to @hari on slack, you will have to ask him for it.
  - Select a plan. 2 or 3 units of Plan VII usually suits our needs for a month of reminder messages.
  - Make payment with a credit card. Note that large transactions (10L) have gotten stuck in the past so its best to buy smaller packs
    every once in a while.
- To check the current account balance, you can run `rake bsnl:get_account_balance` on production.
- We have alerts setup to warn us a week in advance if our balance is running low.

### Managing JWT tokens

- bulksms.bsnl.in uses JWT for authorizing all API requests. The JWT token can be generated using the username and password.
- We can generate upto 5 tokens with our username and password. Each token gets a token ID (1 to 5). The `BSNL_USERNAME` and `BSNL_PASSWORD` is in IHCI's secrets.
  IHCI uses a fixed token ID on the sidekiq box in `BSNL_TOKEN_ID`.
- The JWT tokens have an expiration time (1 year) and we run a job every week to refresh it. The rake task `bsnl:refresh_sms_jwt` fetches a new JWT token 
  and stores it as a `Configuration` object in the DB.
- None of this requires any maintenance in the regular course. In case a new env (other than IHCI prod) wants to use BSNL:
  - Make sure to use a different token ID than production's.
  - Make sure to setup a schedule for refreshing the JWT token on the new env.

### Adding new SMS strings
- Add the new notification strings to the locale file (in `config/notifications/locale`)
- Upload the notification template to the DLT dashboard. The name should follow the format: `locale.locale_key`. Some examples:
  - `en.notifications.set01.basic`
  - `hi-IN.notifications.set03.basic`
  - `ti-ET.notifications.set03.basic_repeated.first`

  The locale in the name on DLT portal needs to be hyphenated (`hi-IN` and not `hi_IN`). This format is used to associate the templates on BSNL to locale keys so it's an important step.
- The template should show up on the BSNL dashboard in a few hours. You will need to name the variables
in the template.

<TODO flesh out these notes on dashboard usage and end-to-end flow, maybe add a video>

### Maintaining template IDs
After a new template has been added to the DLT portal, we need to pull in it's `DLT Template ID` before it can be used as a reminder SMS.
We have a script to help with it.

**Note:** You will need production credentials to run the script.

- Copy over the following vars from India production's `.env` file to your `.env.development.local`:
```
BSNL_IHCI_ENTITY_ID=140xxxx
BSNL_IHCI_HEADER=IHCxxx
BSNL_JWT_TOKEN=eyJhxxxx
```
- Run `bundle exec rake bsnl:get_template_details`.
- This will pull the latest configuration from BSNL and save it to `config/data/bsnl_templates.yml`. This will also output a summary of any actions to be taken, go through them carefully.
- Commit and push changes in this file (if there are any).
- Remove the credentials from `.env.development.local`.
- You are all set to use the new reminder message.

#### Additional notes

- The script pulls all templates listed on IHCI's DLT platform. Although, it runs the validations only for reminder notifications specified in `locale/notifications` and will need tweaks to support other kinds of messages.
- You can run `bundle exec rake bsnl:list_pending_templates` to see which templates still need to be uploaded. This is useful to keep track 
of things when you're adding a lot of templates to the dashboard.
