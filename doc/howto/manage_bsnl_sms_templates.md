## Sending SMSes via BSNL

We use BSNL to send reminder messages in India. This requires us to comply with DLT regulations, which needs us to maintain
a mapping between IDs assigned by DLT and our messages (identified by locale keys).

This is a how-to on interacting with the BSNL and DLT dashboards and maintaining the required mapping with `simple-server`.

<TODO add notes on dashboard usage and end-to-end flow>

### Maintaining template IDs
When a new template is added to the BSNL dashboard, we need to pull in it's `DLT Template ID` before it can be sent as a reminder SMS. We have a script to help with it.

**Note:** You will need production credentials to do this.

- Copy over the following vars from India production's `.env` file to your `.env.development.local`:
```
BSNL_IHCI_ENTITY_ID=140xxxx
BSNL_IHCI_HEADER=IHCxxx
BSNL_JWT_TOKEN=eyJhxxxx
```
- Run `bundle exec rake bsnl:get_template_details`.
- This should pull the latest configuration from BSNL and save it to `config/data/bsnl_template_details.yml`. This will also output a summary of any actions to be taken, go through them carefully.
- Commit and push changes in this file (if there are any).
- Remove the credentials from `.env.development.local`

#### Additional notes

- The script pulls all templates listed on IHCI's DLT platform. Although, it runs the validations only for reminder notifications specified in `locale/notifications` and will need tweaks to support other kinds of messages.
- You can run `bundle exec rake bsnl:list_pending_templates` to see which templates still need to be uploaded. This is useful to keep track 
of things when you're adding a lot of templates to the dashboard.
