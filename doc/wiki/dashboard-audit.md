## Dashboard query audit
Reviewing the following Dashboard queries to ensure we're displaying and describing the data correctly:

1. New registered patients
2. Total registered patients
3. Total assigned patients
4. BP controlled
5. BP not controlled
6. Visited but no BP taken
7. Missed visits
8. Lost to follow-up
9. Follow-up patients
10. BP measure taken
11. Cohort reports

---

## Monthly registered patients
**Copy used in the Dashboard**
Hypertension patients registered during a month in `region_name`

**How it's calculated**
The number of patients registered at a facility during a month where the patient:
+ Is not deleted
+ The patient is hypertensive

*Sample SQL query*
```sql
SELECT Count(DISTINCT "patients"."id") AS count_id,
       Date_trunc('month', "patients"."recorded_at"::timestamptz AT TIME ZONE 'ETC/UTC') AT TIME ZONE 'ETC/UTC' AS date_trunc_month_patients_recorded_at_timestamptz_at_time_zone_
FROM "patients"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
WHERE "patients"."deleted_at" IS NULL
  AND "patients"."registration_facility_id" = $1
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $2
  AND ("patients"."recorded_at" IS NOT NULL)
GROUP BY date_trunc('month', "patients"."recorded_at"::timestamptz AT TIME ZONE 'ETC/UTC') AT TIME ZONE 'ETC/UTC' [["registration_facility_id", "2e768fb2-9de0-4a7d-a64d-9f5b4c1863f4"],["hypertension", "yes"]]"
```

**Where it's shown in the Dashboard** 
+ **Reports:** Overview, Details
+ **Home:** BP controlled, BP not controlled, Missed visits
+ **Simple app:** Progress tab

**Things we should fix**
+ [ ] Rename query name from "Monthly registered patients" to "New registered patients"
+ [ ] Make copy more specific and more closely match how the query is calculated
+ [ ] Resolve query duplication where needed and ensure all queries return the right data

---

## Total registered patients
**Copy used in the Dashboard**
Total hypertension patients registered in `region_name`

**How it's calculated**
The sum of all monthly registrations at a facility

**Where it's shown in the Dashbaord**
+ **Reports:** Overview, Details
+ **Home:** BP controlled, BP not controlled, Missed visits
+ **Simple App:** Progress tab

**Things we should fix**
+ [ ] Make copy more specific and more closely match how the query is calculated
+ [ ] Resolve query duplication where needed and ensure all queries return the right data

---
## Lost to follow-up (LTFU)
**Copy used in the Dashboard**
Hypertension patients with no BP taken in the last 12 months

**How it's calculated**
The number of patients assigned to a facility where the patient:
+ Didn't have a BP recorded within the last year
+ Was registered more than a year ago
+ Is hypertensive
+ Is not dead
+ Is not deleted

*Sample SQL query*
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

**Where it's shown in the Dashboard**
*Note: Anywhere that shows the "BP controlled", "BP not controlled", and "Missed visits" queries use the LTFU query to exclude LTFU patients*
+ **Home:** BP controlled, BP not controlled, Missed visits
+ **Reports:** Overview, Details, Patient line list downloads
+ **Simple app:** Progress tab

**Things we should fix**
+ [ ] Investigate if `overall_patients` method in `BloodPressureControlQuery` is being used
+ [ ] Copy bug, the LTFU "Denominator" is missing a colon in the "Details" definitions section