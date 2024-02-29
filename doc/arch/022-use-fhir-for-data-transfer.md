# Prefer FHIR-compatible payloads for data transfer
## Context

There's been a need for Simple Server to integrate a variety of other
information systems that manage healthcare data—the ability to interoperate
with these systems is desirable for governments who may want to leverage the
[Simple reporting dashboards][reporting] but are already using different
software to collect or store data.

We must adopt a standardised format to make this exchange feasible, while
ensuring that it can sufficiently represent the longitudinal healthcare data
that Simple currently supports.

[reporting]: 004-reporting.md

## Decision

We will work towards providing data imports and exports adhering to the [FHIR
R4 standard][fhir r4] as much as reasonably possible. Given that this is a
vast, flexible and changing standard which is interpreted differently by
various implementers, we do not aim for a strict adherence—we will instead
adhere closely enough to achieve our aims, which are:
1. Reducing the barrier to interoperability
2. Ensuring that there's no loss of fidelity when sharing records
3. Not getting bogged down by the fine print of the standard while achieving
   (1) and (2)

[fhir r4]: http://hl7.org/fhir/R4/

### Why choose FHIR?

FHIR is a standards framework created by HL7 that has a track record of
producing widely adopted standards (such as [CDA][cda]). FHIR leverages the
latest web standards and is seeing rapid adoption across healthcare software.
It has a thoroughly documented data format, which is representable as JSON.

There is plenty of library support, open source projects and backing from cloud
computing platforms. There is even a push for FHIR adoption by governments and
international bodies all over the world.
[[1][usfhir], [2][brfhir], [3][whofhir], [4][infhir]]

As of February 2024, FHIR R4 is the most widely adopted version of FHIR that's
[Normative].

[cda]: http://www.hl7.org/implement/standards/product_brief.cfm?product_id=7
[usfhir]: https://www.cms.gov/newsroom/fact-sheets/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f
[brfhir]: https://www.gov.br/saude/pt-br/composicao/seidigi/rnds/a-solucao-tecnologica
[whofhir]: https://www.who.int/news/item/03-07-2023-who-and-hl7-collaborate-to-support-adoption-of-open-interoperability-standards
[infhir]: https://web.archive.org/web/20230617025907/https://nrces.in/ndhm/fhir/r4/index.html
[Normative]: http://hl7.org/fhir/R4/versions.html#maturity

### Alternatives

Other widely adopted healthcare interoperability standards exist, primarily
developed by HL7, but they are often based on XML and [generally cumbersome]
to translate to and from Simple's data model.

[generally cumbersome]: https://cdasearch.hl7.org/examples/view/Vital%20Signs/Panel%20of%20Vital%20Signs%20in%20Metric%20Units

### Where we differ from the FHIR standard (As of February 2024)

* FHIR does not define a `created_at` field for any resource. This field is
  important for many of our reports, so we added a `Meta.createdAt` field to
  all our resources.
* By default, FHIR expects a [patient] to be associated with only a single
  facility/organization at any given moment. To emulate what Simple does with
  the separation of registered and assigned facilities, we would have to
  create a duplicate patient record for a transferred patient and link them
  together. This makes it highly inconvenient for imports and exports. Due to
  this, we ended up creating an extra field called `registrationOrganization`.
* Appointments in FHIR do not have any direct association to facilities—Simple
  requires a facility ID and creation facility ID (if the appointment was
  created elsewhere). The only way to associate a facility with an appointment
  in FHIR is to create a [Location] resource linked to an [Organization] (ie,
  a Simple facility). Even then, these two levels of indirection won't help us
  model the case where the appointment was created in a different facility.
  Thus we created extra fields: `appointmentOrganization` and
  `appointmentCreationOrganization`.
* We also have a lot of extra constraints on top of the current schema. For
  example, we mandatorily require all blood pressures to be linked to an
  [Organization] which is not strictly required in the FHIR standard
  because our reporting pipelines would not work without it.

[patient]: http://hl7.org/fhir/R4/patient.html
[Location]: http://hl7.org/fhir/R4/location.html
[Organization]: http://hl7.org/fhir/R4/organization.html

### Moving towards total compliance

It's possible for us to towards total FHIR compliance over time by creating
[extensions] and [profiles]. We haven't done so yet because it is a cumbersome,
time-consuming process that requires a bunch of red-tape to be fully compliant,
like publishing a [StructureDefinition] and other [conformance resources].

[extensions]: https://hl7.org/fhir/R4/extensibility.html
[profiles]: https://www.hl7.org/fhir/R4/profiling.html
[StructureDefinition]: http://hl7.org/fhir/R4/structuredefinition.html
[conformance resources]: https://www.hl7.org/fhir/R4/profiling.html#conf-res

## Status

Accepted.

## Consequences

By adopting FHIR, we are opening ourselves to the following benefits:
* We will be more interoperable with healthcare information systems around the
  world—it will be less effort to perform data migrations with the growing
  number of FHIR-compatible systems.
* We will have to define a clear mapping between Simple's data model and FHIR
  resources, which is helpful for talking about the kind of data we store.
* Simple's server can start accepting data from external clients that are not
  the Simple app.

There are some downsides to adopting FHIR in the way we have:
* We may require case-by-case customisation to ensure compatibility with other
  systems with varying FHIR profiles (given the flexibility built into the
  standard).
* Other systems will have to make changes and respect our constraints if they
  have to send data to us.
* There will be some friction for systems that are not FHIR-compatible to use
  our FHIR based APIs for import and export. We mitigate this by extensively

We mitigate the downsides by providing extensive documentation that describes
all the changes we have made to the base standard along with the constraints
that apply to our data.

