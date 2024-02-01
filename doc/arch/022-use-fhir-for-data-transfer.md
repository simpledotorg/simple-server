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

## Status

Accepted.

## Consequences

* We will be more interoperable with healthcare information systems around the 
  world—it will be less effort to perform data migrations with the growing 
  number of FHIR-compatible systems.
* We will have to define a clear mapping between Simple's data model and FHIR 
  resources.
* Simple's server can start accepting data from external clients that are not 
  the Simple app.
* We may require case-by-case customisation to ensure compatibility with other 
  systems with varying FHIR profiles (given the flexibility built into the
  standard).
* There will be some friction for systems that are not FHIR-compatible to use
  our FHIR based APIs for import and export.

