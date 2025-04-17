# Duplicate Records & Deduplication Process

This document outlines the concepts, causes, and processes related to duplicate patient records in our system. It explains how duplicate records are identified, merged automatically, and merged manually.

---

## What Is a Duplicate Record?

A **duplicate record** refers to patients registered with the same BP passport but with different attributes. In our context, duplicate records occur when the same BP passport is used by multiple patient entries, even though their associated data (e.g., name, facility, or other attributes) might differ.

---

## What Might Cause Deduplication?

Several scenarios can lead to duplicate records:

- **Patients with the same BP passport are registered at different facilities.**
- **Patients can move blocks.**
- **Patients referred to a different facility but not assigned in the app.**
- **Patients can choose to go to two different facilities on the same day, without a sync happening between them.**
- **The user has reinstalled the app and a full sync isn't complete; a patient on a recurring visit may get registered again.**
- **The user has cleared the data on the phone without completing the sync, causing recurring patient records to be registered again.**

---

## Identifying Duplicate Records

We use an asynchronous script, **DuplicatePassportAnalytics**, which is run daily and reports duplicate patients across different regions. The report is sent to Prometheus with the following metrics:

- **duplicate_passports_across_facilities** – Count of patients using the same BP passport across different facilities.
- **duplicate_passports_in_same_facility** – Count of patients using the same BP passport in the same facility.
- **duplicate_passports_across_districts** – Count of patients using the same BP passport linked to different districts.
- **duplicate_passports_across_blocks** – Count of patients using the same BP passport linked to different blocks.

This job is scheduled to run daily at **5 AM local time**.

---

## Automatic Duplicate Merging

A scheduled job runs at **2 AM every day** to merge patients who have:
- The same BP passport
- The same full name

These records are merged automatically by the backend. The process is handled by the deduplication merge logic found in our code base:

- **Merging Logic**: See [PatientDeduplication::Deduplicator](https://github.com/simpledotorg/simple-server/blob/master/app/services/patient_deduplication/deduplicator.rb#L21).

### Merging Steps:

1. **Identify the Latest and Earliest Records:**
   - The patient record with the most recent `recorded_at` is considered the **latest**.
   - The one with the oldest `recorded_at` is the **earliest**.

2. **Create a New Patient Record** with:
   - **Full Name, Gender, and Reminder Consent** from the latest patient.
   - **Recorded At, Registration Facility, Registration User, Device Created/Updated At** from the earliest patient.
   - **Assigned Facility and Status** from the latest patient.

3. **Address Merging:**
   - A new address is created with the latest information.
   - Old address records are archived in the `deduplication_logs` table.

4. **DOB and Age:**
   - If any patient record has a DOB, the latest DOB is used.
   - Otherwise, the latest patient’s age and `age_updated_at` are set on the new record.

5. **Prescription Drugs:**
   - PrescriptionDrug records from the latest patient are retained.
   - Other duplicate patients’ prescription_drugs are marked as deleted.
   - New records are created and logged in `deduplication_logs`.

6. **Medical History:**
   - A new MedicalHistory record is created.
   - For attributes (e.g., prior_heart_attack_boolean, prior_stroke_boolean, chronic_kidney_disease_boolean, etc.), a precedence is applied:
     - `{"yes" => 0, true => 1, "no" => 2, false => 3, "unknown" => 4, nil => 5}`
     - Lower numerical values have higher precedence.
   - Other MedicalHistory records are tracked under `deduplication_logs`.

7. **Phone Numbers:**
   - Distinct phone numbers across duplicate records are gathered.
   - New records are created for each and logged.

8. **BP Passport Records:**
   - Distinct identifiers from `PatientBusinessIdentifier` are collected.
   - New records are created for each and logged.

9. **Visits (Encounters/Observations):**
   - All existing Encounters for the duplicate patients are re-created for the new patient record.
   - Observations linked to these encounters are similarly re-created and logged.

10. **Appointments:**
    - All existing appointments are re-created for the new patient.
    - Appointments with the status `scheduled` are updated to **cancelled**, except for the most recent one that was synced.

11. **Teleconsultations:**
    - All existing teleconsultation records are re-created for the new patient and logged.

12. **Cleanup:**
    - All duplicate patient records and their associated older data (addresses, appointments, etc.) are soft-deleted after merging.

---

## Manual Duplicate Merging

Duplicate patient entries can also be managed manually via the dashboard:

- **Dashboard View:**  
  The "Merge Duplicate Patients" tab in the left navigation panel displays potential duplicates.
  <img width="277" alt="Screenshot 2025-04-15 at 10 39 25 AM" src="https://github.com/user-attachments/assets/79427b65-8442-4903-a181-f277e2229821" />

- **Access Control:**
  - **Organization Managers:** Search across all patients (no facility filter).
  - **Facility Managers:** Search is limited to patients within the facilities they manage.


- **Limit:**  
  The dashboard displays a hard-coded maximum of **250 duplicate records**.

- **Process:**
  - Patients with the same BP passport but different full names are flagged as duplicates.
  - Users can select/deselect records to merge.
  - Alternatively, users can skip to the next set of records.

<img width="1377" alt="Screenshot 2025-04-15 at 10 18 00 AM" src="https://github.com/user-attachments/assets/83e2b52e-7f4e-493b-9bf2-66ca0a727df8" />

- **Class Responsible:**  

  The class `PatientDeduplication::Strategies` handles identifying potential duplicates.

---

## Error Handling

During the merging process, if any error occurs (due to data issues or other reasons), the error is reported through Sentry. This helps in diagnosing and resolving issues promptly.

---

## Conclusion

This deduplication process ensures that patient records remain accurate and consistent by:
- Identifying duplicates through asynchronous analytics.
- Automatically merging duplicates with matching names.
- Allowing manual intervention for duplicates with slight differences.
- Logging and handling errors for auditability and troubleshooting.

For further details on the merge logic, refer to the [PatientDeduplication::Deduplicator](https://github.com/simpledotorg/simple-server/blob/master/app/services/patient_deduplication/deduplicator.rb#L21) class in our repository.

---

*This README is part of our documentation on managing duplicate patient records and the deduplication process in our system.*