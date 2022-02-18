To clean PHI from your database, enter a PSQL console and run the following from whatever DB you want to clean.

```
alter table patients drop column full_name cascade;
alter table patients drop column date_of_birth cascade;
alter table patients drop column age_updated_at cascade;
drop table patient_phone_numbers cascade;
drop table addresses cascade;
drop table patient_business_identifiers cascade;
alter table users drop column full_name cascade;
alter table users drop column teleconsultation_phone_number cascade;
alter table users drop column teleconsultation_isd_code cascade;
alter table users drop column role cascade;
alter table users drop column sync_approval_status cascade;
alter table users drop column sync_approval_status_reason cascade;
drop table phone_number_authentications cascade;
drop table email_authentications cascade;
drop table twilio_sms_delivery_details;
drop table call_logs;
drop table exotel_phone_number_details;
drop table passport_authentications;
alter table patients drop column deleted_reason cascade;
drop table ar_internal_metadata;
alter table encounters drop column metadata;
alter table encounters drop column notes;
alter table teleconsultations drop column medical_officer_number;
```
