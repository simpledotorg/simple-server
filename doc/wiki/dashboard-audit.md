## Dashboard query audit
Reviewing the following Dashboard queries to ensure we're displaying and describing the data correctly:

1. [New registered patients](#monthly-registered-patients)
2. [Total registered patients](#total-registered-patients)
3. [Total assigned patients](#total-assigned-patients)
4. [BP controlled](#bp-controlled)
5. [BP not controlled](#bp-not-controlled)
6. [Visited but no BP taken](#visited-but-no-bp-taken)
7. [Missed visits](#missed-visits)
8. [Lost to follow-up](#lost-to-follow-up)
9. [Follow-up patients](#follow-up-patients)
10. [Inactive facilities](#inactive-facilities)
11. [BP measure taken](#bp-measure-taken)
12. [BP log](#bp-log)
13. [Cohort reports](#cohort-reports)

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
+ [ ] Make copy definition more specific and more closely match how the query is calculated
+ [ ] Resolve query duplication where needed and ensure all queries return the right data

---

## Total assigned patients
**Copy used in the Dashboard**
Hypertension patients assigned to `region_name`

**How it's calcualted**
The number of patients assigned to a facility where the patient:
+ Is not deleted
+ Is hypertensive
+ Is not dead

*Sample SQL query*
```sql
SELECT COUNT(DISTINCT "patients"."id") AS count_id,
       DATE_TRUNC('month', "patients"."recorded_at"::timestamptz AT TIME ZONE 'ASIA/KOLKATA') AT TIME ZONE 'ASIA/KOLKATA' AS date_trunc_month_patients_recorded_at_timestamptz_at_time_zone_
FROM "patients"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
WHERE "patients"."deleted_at" IS NULL
  AND "patients"."assigned_facility_id" = $1
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $2
  AND "patients"."status" != $3
  AND ("patients"."recorded_at" IS NOT NULL)
GROUP BY DATE_TRUNC('month', "patients"."recorded_at"::timestamptz AT TIME ZONE 'ASIA/KOLKATA') AT TIME ZONE 'ASIA/KOLKATA' [["assigned_facility_id", "fdbeb339-770f-4021-a81a-44f9bc9a5e79"],["hypertension", "yes"],["status", "dead"]]
```

**Where it's shown in the Dashboard**
+ **Reports:** Overview, Details, Cohort reports
+ **Home:** BP controlled, BP not controlled, Missed visits
+ **Simple App:** Progress tab

**Things we should fix**
+ [ ] Make copy definition more specific and more closely match how the query is calculated
+ [ ] In `reports.js` rename `data-registrations` -> `assigned-patients`
+ [ ] Anything that grabs data from `dashboard_analytics` could display different numbers from the main Reports pages because of differences in when data is cached
+ [ ] Review `UserAnalytics` code paths

---

## BP controlled
**Copy used in the Dashboard**
+ Numerator: Patients with BP <140/90 at their last visit in the last 3 months
+ Denominator: Hypertension patients assigned to `region_name`, registered before the last 3 months. Dead and lost to follow-up patients are excluded.

**How it's calculated**
The number of patients assigned to a facility registered before the last 3 months where the patient:
+ Is hypertensive
+ Is not dead
+ Has a BP measure taken within the last 3 months
+ Last BP measure taken is <140/90

*Sample SQL query*
```sql
SELECT COUNT(*)
FROM
  (SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id) *
   FROM "latest_blood_pressures_per_patient_per_months"
   WHERE (medical_history_hypertension = 'yes')
     AND "latest_blood_pressures_per_patient_per_months"."patient_status" != $1
     AND "latest_blood_pressures_per_patient_per_months"."assigned_facility_id" = $2
     AND (patient_recorded_at <= '2019-07-31 18:29:59.999999')
     AND (bp_recorded_at >= '2019-07-31 18:30:00'
          AND bp_recorded_at <= '2019-10-31 18:29:59.999999')
   ORDER BY latest_blood_pressures_per_patient_per_months.patient_id,
            bp_recorded_at DESC, bp_id) latest_blood_pressures_per_patient_per_months
WHERE (systolic < 140
       AND diastolic < 90) [["patient_status", "dead"],["assigned_facility_id", "399c52a8-4b49-41d4-8704-cc3985ac26e6"]]
```

**Where it's shown in the Dashboard**
+ **Reports:** Overview
+ **Home:** BP controlled
+ **Simple App:** Progress tab

**Things we should fix**
+ [ ] The "Home" and "Reports" pages in the Dashboard use `ControlRateQuery` and the "Progress tab" in the Simple App uses `ControlRateService`. We need to look into these queries and consolidate differences.

---

## BP not controlled
**Copy used in the Dashboard**
+ Numerator: Patients with BP >=140/90 at their last visit in the last 3 months
+ Denominator: Hypertension patients assigned to `region_name`, registered before the last 3 months. Dead and lost to follow-up patients are excluded.

**How it's calculated**
The number of patients assigned to a facility, registered before the last 3 months where the patient:
+ Is hypertensive
+ Is not dead
+ Has a BP measure taken within the last 3 months
+ Last BP measure taken is >=140/90

*Sample SQL query*
```sql
SELECT COUNT(*)
FROM
  (SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id) *
   FROM "latest_blood_pressures_per_patient_per_months"
   WHERE (medical_history_hypertension = 'yes')
     AND "latest_blood_pressures_per_patient_per_months"."patient_status" != $1
     AND "latest_blood_pressures_per_patient_per_months"."assigned_facility_id" = $2
     AND (patient_recorded_at <= '2019-07-31 18:29:59.999999')
     AND (bp_recorded_at >= '2019-07-31 18:30:00'
          AND bp_recorded_at <= '2019-10-31 18:29:59.999999')
   ORDER BY latest_blood_pressures_per_patient_per_months.patient_id,
            bp_recorded_at DESC, bp_id) latest_blood_pressures_per_patient_per_months
WHERE (systolic >= 140
       OR diastolic >= 90) [["patient_status", "dead"],["assigned_facility_id", "399c52a8-4b49-41d4-8704-cc3985ac26e6"]]
```

**Where it's shown in the Dashboard**
+ **Reports:** Overview
+ **Home:** BP not controlled

**Things we should fix**
+ [ ] The "Home" and "Reports" pages in the Dashboard use `ControlRateQuery` and the "Progress tab" in the Simple App uses `ControlRateService`. We need to look into these queries and consolidate differences

---

## Visited but no BP taken
**Copy used in the Dashboard**
+ Numerator: Patients with no BP taken at their last visit in the last 3 months
+ Denominator: Hypertension patients assigned to `region_name`, registered before the last 3 months. Dead and lost to follow-up patients are exclued.

**How it's calculated**
The number of patients assigned to a facility, registered before the last 3 moths where the patient:
+ Is not deleted
+ Is hypertensive
+ Is not dead
+ Has at least one of the following in the last 3 months: An appointment created, A drug refilled, A blood sugar taken
+ Doesn't have a BP recorded within the last 3 months

*Sample SQL query*
```sql
SELECT COUNT(DISTINCT "patients"."id")
FROM "patients"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
LEFT OUTER JOIN latest_blood_pressures_per_patient_per_months ON patients.id = latest_blood_pressures_per_patient_per_months.patient_id
LEFT OUTER JOIN appointments ON appointments.patient_id = patients.id
AND appointments.device_created_at >= '2019-02-28 18:30:00'
AND appointments.device_created_at <= '2019-05-31 18:29:59.999999'
LEFT OUTER JOIN prescription_drugs ON prescription_drugs.patient_id = patients.id
AND prescription_drugs.device_created_at >= '2019-02-28 18:30:00'
AND prescription_drugs.device_created_at <= '2019-05-31 18:29:59.999999'
LEFT OUTER JOIN blood_sugars ON blood_sugars.patient_id = patients.id
AND blood_sugars.recorded_at >= '2019-02-28 18:30:00'
AND blood_sugars.recorded_at <= '2019-05-31 18:29:59.999999'
WHERE "patients"."deleted_at" IS NULL
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $1
  AND "patients"."status" != $2
  AND (bp_recorded_at > '2018-05-31'
       AND bp_recorded_at < '2019-05-31 18:29:59.999999'
       OR patients.recorded_at >= '2018-05-31')
  AND "patients"."assigned_facility_id" IN $3
  AND (patients.recorded_at <= '2019-02-28 18:30:00')
  AND (appointments.id IS NOT NULL
       OR prescription_drugs.id IS NOT NULL
       OR blood_sugars.id IS NOT NULL)
  AND (NOT EXISTS
         (SELECT 1
          FROM blood_pressures bps
          WHERE patients.id = bps.patient_id
            AND bps.recorded_at >= '2019-02-28 18:30:00'
            AND bps.recorded_at <= '2019-05-31 18:29:59.999999')) [["hypertension", "yes"],
                                                                   ["status", "dead"],
                                                                   ["assigned_facility_id", "3a7e86d2-c272-4303-8ffa-d6d1b54874b3"]]
```

**Where it's shown in the Dashboard**
+ **Reports:** Overview

**Things we should fix**
+ [ ] Review LTFU code paths in `Result` and `Repository` objects

---

## Missed visits
**Copy used in the Dashboard**
+ Numerator: Patients with no visit in the last 3 months
+ Denominator: Hypertension patients assigned to `region_name`, registered before the last 3 months. Dead and lost to follow-up patients are excluded.

**How it's calculated**
  Total assigned patients (registered before the last 3 months)
— Patients with a visit but no BP taken 
— Patients with controlled BP
— Patients with uncontrolled BP
= Missed visits

*The SQL query is a combination of all the queries in the equation above*

**Where it's shown in the Dashboard**
+ **Reports:** Overview
+ **Home:** Missed visits

**Things we should fix**
+ [ ] Determine if there is a bug (see `calculate_missed_visits`) and how to make this easier to follow going forward
+ [ ] Rename missed visits method names in `blood_pressure_control_query.rb` to use `no_bp_taken...`

---

## Lost to follow-up
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

---

## Follow-up patients
**Copy used in the Dashboard**
Hypertension patients with a BP measure taken during a month in `region_name`

**How it's calculated**
The number of patients assigned to a facility during a month where the patient:
+ Had a BP taken during a month
+ Is hypertensive
+ Is not deleted
+ Was not registered during that month

*Sample SQL query*
```sql
SELECT COUNT (DISTINCT "patients"."id") AS count_id,
             DATE_TRUNC('month', blood_pressures.recorded_at::timestamptz AT TIME ZONE 'ASIA/KOLKATA') AT TIME ZONE 'ASIA/KOLKATA' AS date_trunc_month_blood_pressures_recorded_at_timestamptz_at_tim,
             "blood_pressures"."facility_id" AS blood_pressures_facility_id
FROM "patients"
INNER JOIN "blood_pressures" ON "blood_pressures"."deleted_at" IS NULL
AND "blood_pressures"."patient_id" = "patients"."id"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
WHERE "patients"."deleted_at" IS NULL
  AND (patients.recorded_at < (DATE_TRUNC('month', (blood_pressures.recorded_at::timestamptz) AT TIME ZONE 'ASIA/KOLKATA')) AT TIME ZONE 'ASIA/KOLKATA')
  AND (blood_pressures.recorded_at IS NOT NULL)
  AND "blood_pressures"."facility_id" IN $1
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $24
GROUP BY DATE_TRUNC('month', blood_pressures.recorded_at::timestamptz AT TIME ZONE 'ASIA/KOLKATA') AT TIME ZONE 'ASIA/KOLKATA', "blood_pressures"."facility_id" [["facility_id", "3a7e86d2-c272-4303-8ffa-d6d1b54874b3"],
                                                                                                                                                                 ["hypertension", "yes"]]
```

**Where it's shown in the Dashboard**
+ **Reports:** Details
+ **Simple App:** Progress tab

**Things we should fix**
*Nothing to fix*

---

## Inactive facilities
**Copy used in the Dashboard**
Facilities where <10 patients had any BPs recorded in the last 7 days

**How it's calculated**
First we calculate total active facilities (Facilities where <10 patients had any BPs recorded in the last 7 days). Then we:
+ Grab all facilties the admin has access to
+ Count the total number of patients with a BP taken in a day for the last 7 days at each facility
+ Returns the number of facilities where the facility has had more than 10 patients with a BP taken in the last week

To calculate inactive facilities, the query grabs all the other facilities the admin has access to (inactive = total facilities - active facilities)

*Sample SQL query*
```sql
SELECT "blood_pressures_per_facility_per_days"."facility_id"
FROM "blood_pressures_per_facility_per_days"
WHERE "blood_pressures_per_facility_per_days"."deleted_at" IS NULL
  AND "blood_pressures_per_facility_per_days"."facility_id" IN
    (SELECT "facilities"."id"
     FROM "facilities"
     WHERE "facilities"."deleted_at" IS NULL
       AND "facilities"."id" IN
         (SELECT "facilities"."id"
          FROM (
                  (SELECT "facilities".*
                   FROM "facilities"
                   WHERE "facilities"."deleted_at" IS NULL)
                UNION
                  (SELECT "facilities".*
                   FROM "facilities"
                   WHERE "facilities"."deleted_at" IS NULL
                     AND "facilities"."facility_group_id" IN
                       (SELECT id
                        FROM (
                                (SELECT "facility_groups".*
                                 FROM "facility_groups"
                                 WHERE "facility_groups"."deleted_at" IS NULL
                                   AND "facility_groups"."deleted_at" IS NULL)
                              UNION
                                (SELECT "facility_groups".*
                                 FROM "facility_groups"
                                 WHERE "facility_groups"."deleted_at" IS NULL
                                   AND "facility_groups"."deleted_at" IS NULL
                                   AND "facility_groups"."organization_id" IN
                                     (SELECT "organizations"."id"
                                      FROM "organizations"
                                      WHERE "organizations"."deleted_at" IS NULL))) "facility_groups"))) "facilities"))
  AND (((YEAR,
         DAY) IN (('2021',
                   '91'),('2021',
                          '90'),('2021',
                                 '89'),('2021',
                                        '88'),('2021',
                                               '87'),('2021',
                                                      '86'),('2021',
                                                             '85'))))
GROUP BY "blood_pressures_per_facility_per_days"."facility_id"
HAVING (SUM(bp_count) >= 10)
```

**Where it's shown in the Dashboard**
+ **Home:** "Facilities using Simple" and "Inactive facilities" cards

**Things we should fix**
+ [X] Update "Facilities using Simple" subtitle to be "Inactive facilities <10 patients with BPs recorded in the last 7 days"

**CVHO feedback** ([see CVHO WhatsApp conversation](https://simpledotorg.slack.com/archives/CK95QFJA2/p1617571926001200))
+ CVHOs suggest we don't count facilities with <3 registered patients as inactive
+ CVHOs suggest we redefine inactive facilities to be "facilities with <10 patients with a BP recorded in the last 30 days

---

## BP measure taken
**Copy used in the Dashboard**
All BP measures taken in a month by healthcare workers at `region_name`

**How it's calculated**
Counts all blood pressures recorded by each user at a facility where the patient:
+ Is hypertensive
+ Is not deleted 

*Sample SQL query*
```sql
SELECT Count(DISTINCT "blood_pressures"."id") AS count_id,
       Date_trunc('month', "blood_pressures"."recorded_at"),
       "blood_pressures"."user_id" AS blood_pressures_user_id
FROM "blood_pressures"
INNER JOIN "patients" ON "patients"."deleted_at" IS NULL
AND "patients"."id" = "blood_pressures"."patient_id"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
WHERE "blood_pressures"."deleted_at" IS NULL
  AND "patients"."deleted_at" IS NULL
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $1
  AND ("blood_pressures"."recorded_at" IS NOT NULL)
  AND "blood_pressures"."facility_id" IN
    (SELECT "facilities"."id"
     FROM "facilities"
     WHERE "facilities"."deleted_at" IS NULL
       AND "facilities"."id" = $2) GROUP  BY Date_trunc('month', "blood_pressures"."recorded_at"),
                                             "blood_pressures"."user_id"
```

**Where it's shown in the Dashboard**
+ **Facility Report:** Details

**Things we should fix**
*Nothing*

---

## BP log
**Copy used in the Dashboard**
A log of BP measures taken by healthcare workers at `region_name`

**How it's calculated**
All blood pressures recorded at a facility

```sql
SELECT "blood_pressures".*
FROM "blood_pressures"
INNER JOIN "observations" ON "blood_pressures"."id" = "observations"."observable_id"
INNER JOIN "encounters" ON "observations"."encounter_id" = "encounters"."id"
WHERE "blood_pressures"."deleted_at" IS NULL
  AND "observations"."deleted_at" IS NULL
  AND "encounters"."deleted_at" IS NULL
  AND "encounters"."facility_id" = $1
  AND "observations"."observable_type" = $2
ORDER BY DATE(recorded_at) DESC, recorded_at ASC
LIMIT $3
OFFSET $4 [["facility_id", "acc3da36-c5d2-42e1-a1fe-29d6a40b0580"],
           ["observable_type", "BloodPressure"],
           ["LIMIT", 20],
           ["OFFSET", 0]]
```

**Where it's shown in the Dashboard**
+ **Facility Report:** Details

**Things we should fix**
*Nothing*

---

## Cohort reports
**Copy used in the Dashboard**
The result for all assigned hypertensive patients registered in a month at their follow-up visit in the following two months.

**How it's calculated**
+ BP controlled numerator: The number of patients assigned to a facility registered during a month where the patient:
  + Is hypertensive
  + Is not deleted
  + Is not dead
  + Has a last BP in the following 2 months
  + Last BP is <140/90
+ BP not controlled numerator: The number of patients assigned to a facility registered during a month where the patient:
  + Is hypertensive
  + Is not deleted
  + Is not dead
  + Has a last BP in the following 2 months
  + Last BP is >=140/90
+ Missed visits numerator: The number of patients assigned to a facility registered during a month - Number of patients with a BP taken in the following 2 months
+ Denominator: The number of patients assigned to a facility where the patient:
  + Is hypertensive
  + Is not deleted
  + Is not dead

*Sample SQL denominator query*
```sql
SELECT COUNT(DISTINCT "patients"."id")
FROM "patients"
INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
AND "medical_histories"."patient_id" = "patients"."id"
WHERE "patients"."deleted_at" IS NULL
  AND "medical_histories"."deleted_at" IS NULL
  AND "medical_histories"."hypertension" = $1
  AND "patients"."status" != $2
  AND "patients"."assigned_facility_id" IN
    (SELECT "facilities"."id"
     FROM "facilities"
     WHERE "facilities"."deleted_at" IS NULL
       AND "facilities"."id" IN
         (SELECT "facilities"."id"
          FROM "facilities"
          WHERE "facilities"."deleted_at" IS NULL
            AND "facilities"."id" = $3))
  AND (recorded_at >= '2021-02-28 18:30:00'
       AND recorded_at <= '2021-03-31 18:29:59.999999') [["hypertension", "yes"],
                                                         ["status", "dead"],
                                                         ["id", "acc3da36-c5d2-42e1-a1fe-29d6a40b0580"]]
```

*Sample SQL BP controlled numerator*
```sql
SELECT COUNT(*)
FROM
  (SELECT DISTINCT ON (patient_id) *
   FROM "latest_blood_pressures_per_patient_per_months"
   WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
     AND "latest_blood_pressures_per_patient_per_months"."patient_id" IN
       (SELECT DISTINCT "patients"."id"
        FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."patient_id" = "patients"."id"
        WHERE "patients"."deleted_at" IS NULL
          AND "medical_histories"."deleted_at" IS NULL
          AND "medical_histories"."hypertension" = $1
          AND "patients"."status" != $2
          AND "patients"."assigned_facility_id" IN
            (SELECT "facilities"."id"
             FROM "facilities"
             WHERE "facilities"."deleted_at" IS NULL
               AND "facilities"."id" IN
                 (SELECT "facilities"."id"
                  FROM "facilities"
                  WHERE "facilities"."deleted_at" IS NULL
                    AND "facilities"."id" = $3))
          AND (recorded_at >= '2021-02-28 18:30:00'
               AND recorded_at <= '2021-03-31 18:29:59.999999'))
     AND ((YEAR = '2021'
           AND MONTH = '4')
          OR (YEAR = '2021'
              AND MONTH = '5'))
   ORDER BY patient_id,
            bp_recorded_at DESC, bp_id) latest_blood_pressures_per_patient_per_months
WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
  AND (systolic < 140
       AND diastolic < 90) [["hypertension", "yes"],
                            ["status", "dead"],
                            ["id", "acc3da36-c5d2-42e1-a1fe-29d6a40b0580"]]
```

*Sample SQL BP not controlled query*
```sql
SELECT COUNT(*)
FROM
  (SELECT DISTINCT ON (patient_id) *
   FROM "latest_blood_pressures_per_patient_per_months"
   WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
     AND "latest_blood_pressures_per_patient_per_months"."patient_id" IN
       (SELECT DISTINCT "patients"."id"
        FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."patient_id" = "patients"."id"
        WHERE "patients"."deleted_at" IS NULL
          AND "medical_histories"."deleted_at" IS NULL
          AND "medical_histories"."hypertension" = $1
          AND "patients"."status" != $2
          AND "patients"."assigned_facility_id" IN
            (SELECT "facilities"."id"
             FROM "facilities"
             WHERE "facilities"."deleted_at" IS NULL
               AND "facilities"."id" IN
                 (SELECT "facilities"."id"
                  FROM "facilities"
                  WHERE "facilities"."deleted_at" IS NULL
                    AND "facilities"."id" = $3))
          AND (recorded_at >= '2021-02-28 18:30:00'
               AND recorded_at <= '2021-03-31 18:29:59.999999'))
     AND ((YEAR = '2021'
           AND MONTH = '4')
          OR (YEAR = '2021'
              AND MONTH = '5'))
   ORDER BY patient_id,
            bp_recorded_at DESC, bp_id) latest_blood_pressures_per_patient_per_months
WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
  AND (systolic >= 140
       OR diastolic >= 90) [["hypertension", "yes"],
                            ["status", "dead"],
                            ["id", "acc3da36-c5d2-42e1-a1fe-29d6a40b0580"]]
```

*Sample SQL missed visits numerator*
```sql
SELECT COUNT(*)
FROM
  (SELECT DISTINCT ON (patient_id) *
   FROM "latest_blood_pressures_per_patient_per_months"
   WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
     AND "latest_blood_pressures_per_patient_per_months"."patient_id" IN
       (SELECT DISTINCT "patients"."id"
        FROM "patients"
        INNER JOIN "medical_histories" ON "medical_histories"."deleted_at" IS NULL
        AND "medical_histories"."patient_id" = "patients"."id"
        WHERE "patients"."deleted_at" IS NULL
          AND "medical_histories"."deleted_at" IS NULL
          AND "medical_histories"."hypertension" = $1
          AND "patients"."status" != $2
          AND "patients"."assigned_facility_id" IN
            (SELECT "facilities"."id"
             FROM "facilities"
             WHERE "facilities"."deleted_at" IS NULL
               AND "facilities"."id" IN
                 (SELECT "facilities"."id"
                  FROM "facilities"
                  WHERE "facilities"."deleted_at" IS NULL
                    AND "facilities"."id" = $3))
          AND (recorded_at >= '2021-02-28 18:30:00'
               AND recorded_at <= '2021-03-31 18:29:59.999999'))
     AND ((YEAR = '2021'
           AND MONTH = '4')
          OR (YEAR = '2021'
              AND MONTH = '5'))
   ORDER BY patient_id,
            bp_recorded_at DESC, bp_id) latest_blood_pressures_per_patient_per_months
WHERE "latest_blood_pressures_per_patient_per_months"."deleted_at" IS NULL
```

**Where it's shown in the Dashboard**
+ **Reports:** Cohort Reports
+ **Simple App:** Progress tab

**Things we should fix**
+ [ ] Check with Dr. Reena if "Visit but no BP taken" should be added to Cohort reports
+ [X] Rename `BloodPressureControlQuery` so that it includes 'cohort' in the name (i.e. `BloodPressureControlCohortQuery`)