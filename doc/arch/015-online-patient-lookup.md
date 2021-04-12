# Online Patient Lookup

## Status

Proposed on 2020-04-12

## Context

Want want to ensure that a patient’s medical records within the state
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
information from the server. This will be a static number to begin
with, but can later vary depending on the state, country or other
factors.

We will implement temporary retention in the app with this
feature. With every patient retrieved via the lookup API, we will:

- ensure the data is synced to the server
- delete the data after the retention time period has passed

< @mobile-devs: please add details on possible approaches here >

Note that the retention time period is not strict. i.e,
it is okay for the record to stay on the phone for 2h if the retention
period is 1h. We can perform deletions at a convenient time as long as
the deletion happens deterministically.

_Alternatively_: we can choose to hard-code the retention period on
the app.

### API contract
For the request, we will use the endpoint `GET`:
https://api.simple.org/api/v4/patient/identifier/, where `identifier`
is any valid patient business identifier.

In the response, will return a _list of patients_ that have that
identifer. Note that it is possible for more than a single patient to
have the same identifier. The response contract will be similar to
[the API used in the BP Passport
App](https://api.simple.org/api-docs#tag/Patient/paths/~1patient/get):

````
{"retention": {
    "type": "temporary",
    "duration_seconds": 3600
 }
 "patients": [{
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
    "business_identifiers": []
  }]
}
````

_Alternatively_: We could use a v5 prefix to disambiguate with the
Passport app lookup API more clearly.

### Access restrictions
All data that can be sync'd to facilities in the State can be returned
successfully. Data outside the state will return 403.

### Audit logging
Similar to the sync API, we will create a _lookup audit log_ for
successful lookups performed using this API. This will have the
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

_Alternatively_: we can try to repurpose the existing audit logs for
this, while capturing all the information.

### Rate limiting
We currently rate limit our authentication endpoints using
[rack-attack](https://github.com/rack/rack-attack). We will do the
same for this API.

## Consequences
- We could potentially reduce the memory footprint of the app further
by using the retention periods for other non-lookup use-cases.
