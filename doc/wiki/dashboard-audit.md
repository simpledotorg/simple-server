## Dashboard query audit

## Lost to follow-up (LTFU)
**Copy used to define query in the Dashboard**:
Hypertension patients with no BP taken in the last 12 months

**How we calculate LTFU in the Dashboard**
For each patient, if the patient
+ Didn't have a BP recorded within the last year
+ Was registered more than a year ago
+ Is hypertensive
+ Is not dead
+ Is not deleted

*Sample SQL query for "Lost to follow-up"*
```sql
SELECT DISTINCT "patients".*
FROM "patients"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id
AND bp_recorded_at > '2020-04-30' /* Date from 1 year ago: 1 year is the LTFU period */
AND bp_recorded_at < '2021-04-30 23:59:59.999999' /* Current date */
WHERE "patients"."deleted_at" IS NULL
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = 'yes'
  AND "patients"."status" != 'dead'
  AND "patients"."assigned_facility_id" = 'ad0ff5e2-7f0f-467b-9855-07b894e4a6a7'
  AND (bp_recorded_at IS NULL
       AND patients.recorded_at < '2020-04-30') /* Date from 1 year ago */
```

**Parts of our Dashboard that display the queries**
*Note: Anywhere that shows the "BP controlled", "BP not controlled", and "Missed visits" queries use the LTFU query to exclude LTFU patients*
+ **Home:** BP controlled, BP not controlled, Missed visits
+ **Reports:** Overview, Details, Patient line list downloads
+ **Simple app:** Progress tab

**Things we should fix**
+ [ ] Investigate if `overall_patients` method in `BloodPressureControlQuery` is being used
+ [ ] Copy bug, the LTFU "Denominator" is missing a colon in the "Details" definitions section