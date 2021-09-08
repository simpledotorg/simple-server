# Online Patient Lookup

## Status

Accepted on 2020-04-20
Proposed on 2020-04-12

## Context

We want to ensure that a patient’s medical records within the state
are always available to the nurse for treatment if they are connected
to the internet. See related
[PRD](https://docs.google.com/document/d/1q6cppByQULfh3_mMXC4BJpiNN9Uc_awA6rreeEtUBaM/edit#)
for more details on the feature and related specifications.

The lookup will be a new API on the server that the mobile app will
call. The following aspects of the problem are addressed in this ADR:

- API contract
- Data retention
- Access restrictions
- Audit logging
- Rate limiting

## Decision
### Data retention
There are two broad kinds of data retention on the app at a facility:
1. Permanent: patient is within sync criteria: the same block, has an
   appointment, or is assigned to the facility
2. Temporary: patient is not within the sync criteria

In order to have a better control of the retention, we will send this
information as `retention type` from the server. We will also send a
`retention duration` in seconds, which will be a static number to
begin with, but can later vary depending on the state, country or
other factors. See the API contract below for more details.

We will implement temporary retention in the app with this
feature. With every patient retrieved via the lookup API, we will
store the time until which the record needs to be retained if the
retention type is temporary.

```
retain_until = sync_time (now) + retention duration
```

After a sync (that happens every 15 minutes), we will delete the
records that:
- should be retained temporarily
- and have passed their retention time period: `now > retain_until`

If a `temporary` record is synced via the sync API, then the retention
type should be set to `permanent`.

We will treat manual and automatic syncs in the same way, and
configure the retention period to suit the needs of showing patients
in the recent list, etc.

~~_Alternatively_: we can choose to hard-code the retention period on
the app.~~

### API contract
For the request, we will use the endpoint `GET`:
https://api.simple.org/api/v4/patients/identifier/, where `identifier`
is any valid patient business identifier.

The type of the identifier will not be specified in the request because:
- the client might not be able to discern the type
- the same identifier might exist across different types (BP passport,
  NHID, or a future type)

In the response, will return a _list of patients_ that have that
identifer. Note that it is possible for more than a single patient to
have the same identifier. The response contract will be similar to
[the API used in the BP Passport
App](https://api.simple.org/api-docs#tag/Patient/paths/~1patient/get):

````
{ "patients": [{
    "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
    "full_name": "string",
    "age": 0,
    "gender": "male",
    "status": "active",
    "recorded_at": "2019-08-24T14:15:22Z",
    "reminder_consent": "granted",
    "phone_numbers": [],
    "address": {...},
    "registration_facility": {...},
    "medical_history": {...},
    "blood_pressures": [],
    "blood_sugars": [],
    "appointments": [],
    "medications": [],
    "business_identifiers": [],
    "retention": {
      "type": "temporary", // or "permanent"
      "duration_seconds": 3600
    }
  }]
}
````

This API will have a 5s timeout from the android app to prevent delay
in patient care.

~~_Alternatively_: We could use a v5 prefix to disambiguate with the
Passport app lookup API more clearly.~~

### Access restrictions
Access for this API will be restricted to the state that the user is
registered in. Trying to lookup a patient that resides outside the
state will return 404.

If a patient has travelled across states, and has records in both
states corresponding to the same identifier, then only the patients
belonging to the requesting user's state will be returned in the API.

### Audit logging
Similar to the sync API, we will create a _lookup audit log_ for
successful lookups performed using this API. This is separate from the
sync audit log since looking up a specific patient is conceptually
different from fetching the block's patients. This will have the
following fields in it:

````
{
  user_id: user.id,
  facility_id: current_facility.id,
  identifier: identifier,
  patient_ids: [patient_id],
  time: Time.current
}
````

~~_Alternatively_: we can try to repurpose the existing audit logs for
this, while capturing all the information.~~

### Rate limiting
We currently rate limit our authentication endpoints using
[rack-attack](https://github.com/rack/rack-attack). We will do the
same for this API. See the [relevant section in the
PRD](https://docs.google.com/document/d/1q6cppByQULfh3_mMXC4BJpiNN9Uc_awA6rreeEtUBaM/edit#)
for the rationale and the chosen rate limiting configuration.

## Consequences
- There will be synchronous requests to the server during the patient
  care hours. So, the server going down for a few minutes will have
  consequences on the number of duplicate registrations.
- We could potentially reduce the memory footprint of the app further
  by using the retention periods for other non-lookup use-cases.
- We could repurpose temporary retention in the app to implement
  access restricted by time in the future, if needed.
