# Kandy District Facility Performance Report (Hypertension)

Date: 2026-03-25  
Reporting period used for facility ranking: Feb 2026 (Hypertension report)

## 1) Data sources used

1. **Kandy Hypertension report** (`Kandy___Hypertension1.txt`)  
   - Used for facility-level performance ranking.
2. **District report CSV** (`01___district_report_2026-03-25T08_59_40.603697Z.csv`)  
   - District-level context only.
3. **Statin coverage CSV** (`district_level____of_patients_with_dm_and_aged__40__or_a_history_of_stroke_heart_attack_or_cv____20_prescribed_statins_report_2026-03-25T08_59_33.159964Z.csv`)  
   - District-level context only.

## 2) Important note on scope

Only the Hypertension report contains **facility-level rows**.  
The other two sources are district-level and do not support facility-by-facility ranking.

## 3) Ranking method

Facilities were ranked using:

- BP controlled % (higher is better)
- BP not controlled % (lower is better)
- Missed visits % (lower is better)

Composite score:

`Score = 0.5 * (BP controlled %) + 0.3 * (100 - BP not controlled %) + 0.2 * (100 - Missed visits %)`

To reduce distortion from very small sites, a minimum volume filter was applied:

- **Included in main ranking:** facilities with >= 500 registered HTN patients

District benchmark (same report):

- BP controlled: 54%
- BP not controlled: 26%
- Missed visits: 17%

## 4) Best-performing facilities (>=500 patients)

| Rank | Facility | Registered | BP controlled | BP not controlled | Missed visits | Composite score |
|---|---|---:|---:|---:|---:|---:|
| 1 | Jambugahapitiya | 1,599 | 81% | 9% | 9% | 86.0 |
| 2 | Batumulla | 530 | 79% | 8% | 12% | 84.7 |
| 3 | Galaha | 1,832 | 75% | 7% | 15% | 82.4 |
| 4 | Suduhumpola | 584 | 73% | 14% | 13% | 79.7 |
| 5 | Medadumbara | 1,228 | 68% | 10% | 16% | 77.8 |

## 5) Worst-performing facilities (>=500 patients)

| Rank (worst) | Facility | Registered | BP controlled | BP not controlled | Missed visits | Composite score |
|---|---|---:|---:|---:|---:|---:|
| 1 | Pamunuwa | 789 | 0% | 0% | 100% | 30.0 |
| 2 | Udathalawinna | 597 | 20% | 7% | 63% | 45.3 |
| 3 | Mahakanda | 577 | 32% | 41% | 26% | 48.5 |
| 4 | Narampanawa | 644 | 34% | 41% | 25% | 49.7 |
| 5 | Kadugannawa | 3,423 | 36% | 45% | 12% | 52.1 |

## 6) Rationale for ranking

1. **Outcome-first prioritization:** BP control is weighted highest because it is the primary clinical outcome.
2. **Risk burden included:** High uncontrolled BP penalizes score strongly.
3. **Retention included:** Missed visits captures continuity-of-care failure.
4. **Scale-sensitive interpretation:** A volume threshold is used to avoid over-interpreting very small facilities.
5. **Programmatic impact:** Large low-performing facilities (e.g., Kadugannawa) are high-priority because district-level gains depend on them.

## 7) Prioritized intervention matrix for worst performers

| Priority | Facility | Main gap pattern | Immediate actions | Process KPI | Outcome KPI |
|---|---|---|---|---|---|
| 1 (Critical) | Pamunuwa | 100% missed, no outcome capture | Rapid data-quality and service-availability audit; generate full no-visit line list; active recall (phone + field); restore BP capture at every return visit | % overdue patients contacted; % return visits with BP measured | BP controlled % recovery from 0%; missed visits % reduction |
| 2 | Udathalawinna | Very high missed visits (63%) | Defaulter micro-plans by risk group; dedicated catch-up clinic slots; refill fast-track for overdue patients; weekly follow-up review | % missed patients reached; % returned within cycle | Missed visits % decline; BP controlled % increase |
| 3 | Mahakanda | High uncontrolled (41%) + high missed (26%) | Uncontrolled registry with protocolized titration; medicine stock assurance; adherence counseling bundle; early re-review for uncontrolled patients | % uncontrolled reviewed under protocol | Uncontrolled % decrease; controlled % increase |
| 4 | Narampanawa | High uncontrolled (41%) + high missed (25%) | Same model as Mahakanda; focus on appointment reliability and dose-intensification fidelity | % uncontrolled with treatment step-up documented | Controlled % increase; missed % decrease |
| 5 | Kadugannawa | Very high uncontrolled (45%) at high volume | High-volume uncontrolled stream; BP measurement quality check (staff/device); cohort review meetings; prioritize highest-risk cases first | % uncontrolled cohort reviewed monthly | Uncontrolled % drop from 45%; district-level controlled % gain |

## 8) District-level context from the other two reports

- District and quarterly indicators show broader trend context but are not facility-specific.
- Statin coverage is improving at district level, which is positive for CVD prevention strategy.
- Facility action should still be targeted based on the hypertension facility table above.
