# QI reports: district quality improvement PDFs in the dashboard

## Status

Accepted

## Context

Program teams (first Bangladesh) get district-level quality improvement (QI) reports, such as the Titration
trend, as PDFs built from Metabase questions and sent by email. We want the latest report for each district
inside the dashboard, visible only to users who can see that district, and regenerated on a schedule.

## Decision

1. A standalone "QI reports" tab (`/qi_reports`) lists a district's PDFs in an inline viewer with Download
   and Print. It is switched on per country with `CountryConfig[:qi_reports][:enabled]` (only Bangladesh).
1. PDFs are plain files in `storage/qi_reports` (a Capistrano linked directory), named
   `<Report> - <District> - <period>.pdf`, and are served through `authorize` so a user only gets reports for
   districts they can view reports for. They are never served from `public/`.
1. The PDFs are built by a Python script, `script/qi_reports/publish_district_reports.py`, from Metabase
   questions. It runs monthly on the 3rd (cron entry in `config/schedule.rb`, behind the Flipper flag
   `qi_reports_monthly_job`), covering the last full month and the 5 before it, and each run replaces the
   older PDFs for the same report and district. Reports not refreshed for 120 days are removed.
1. Per-country settings for the script (Metabase questions, filter names, wording, excluded places) live with
   the other country settings, in `CountryConfig[:qi_reports][:script]`
   (`config/initializers/country_config.rb`). `bin/rails qi_reports:settings[PATH]` writes them out as JSON,
   which the script reads (`--settings-file`).

## Details

### Which countries see the tab

The QI reports tab, the `/qi_reports` page and the report file URLs are **off unless a country enables them**:
`CountryConfig[:qi_reports][:enabled]` in `config/initializers/country_config.rb`. Right now only
**Bangladesh** has `enabled: true`. Ethiopia has its settings but `enabled: false` until its report script has
been tested against its Metabase; every other country has no `qi_reports` setting, so the tab is hidden and the
URLs return 404. To switch a country on, set `enabled: true` there (and add its `script:` settings in the
same place). The Bangladesh monthly cron job has its own Flipper flag, `qi_reports_monthly_job`.

### Production schedule (Bangladesh)

- **When:** monthly, on the **3rd** of each month (cron entry `0 10 3 * *` in `config/schedule.rb`, in
  the server's time zone).
- **What:** `script/qi_reports/run_monthly.sh bangladesh` runs `publish_district_reports.py --monthly`: the
  report for the **last full month**, covering that month and the 5 before it, so **6 months of data** per PDF
  (`months` in the Bangladesh `script:` settings). Example: the run on 3 Nov 2026 reports May to October 2026 and
  names the files `Titration - <District> - Oct 2026.pdf`.
- **Disk use:** each run replaces the previous report for a report and district, so the folder holds one PDF
  (about 40 KB) per report and district, roughly 5 MB for Bangladesh. Reports not refreshed for 120 days (for
  example a district that was removed or renamed) are deleted at the end of a run (`QI_PRUNE_DAYS`, default 120).
- **Overwrite:** when a new report is published, every older PDF for the same report and district is deleted
  first, so only the latest report per district is kept. A district that fails in a run keeps its previous
  report; the run logs which districts were skipped and exits non-zero.
- **Off by default:** the cron entry only exists when the Flipper flag `qi_reports_monthly_job` is on and
  the country is Bangladesh. Enable it after the setup below is done and a manual run has worked.

#### Setup on the server

1. Python 3 with `pip install -r script/qi_reports/requirements.txt` (a virtualenv is fine; set `QI_PYTHON`
   to its python). The script needs outbound HTTPS to the Metabase.
2. Create the settings file `settings.bangladesh.sh` (see `settings.sh.example`) with `MB_URL` and `MB_KEY`
   in `$QI_SETTINGS_DIR` (default `/home/deploy/apps/simple-server/shared/qi_reports/`). Keep it out of the
   repo; the key's group must be able to read the Titration question's collection.
3. `storage/qi_reports` is now a Capistrano `linked_dirs` entry (`config/deploy.rb`), so the PDFs live in
   `shared/storage/qi_reports` and survive deploys. The script writes there (`QI_REPORTS_DIR`, default the
   same path). The old sample PDFs were removed from the repo.
4. Test by hand as the deploy user, without publishing:
   `cd script/qi_reports && QI_REPORTS_DIR=/tmp/qi_test ./run_monthly.sh bangladesh` (it publishes into
   `QI_REPORTS_DIR`, so point it somewhere harmless first), then run it against the shared folder.
5. Enable the flag (`Flipper.enable(:qi_reports_monthly_job)`) and redeploy so `whenever` writes the cron entry.
6. If the app runs on several servers, the shared folder must be shared between them, or use object storage
   instead (see "For the engineer"). This script has no S3 support yet.
7. **Statins** is not part of the production run: its question is too slow to run through the API and the
   script falls back to a downloaded CSV (`statins.csv`), which does not exist on the server. The run just
   skips Statins with a warning. See "Statins" below.

### What it is

A standalone **QI reports** tab in the dashboard sidebar (above Facility trends) at `/qi_reports`.

- Two tabs: **Titration reports** and **Statins report** (the report name in the PDF filename picks the tab).
- **Division** and **District** dropdowns. Division comes from the district's state region in Simple.
  A district that matches no region is grouped under "Other". If only one district is available it is
  selected automatically. A **Period** dropdown appears when a district has more than one report
  (a finished month plus a month-to-date one).
- The report is shown in an inline viewer, with **Download PDF** and **Print** top right.
- The PDFs come from a script (`script/qi_reports/`) that reads Metabase and builds one PDF per district.

#### Code

| Piece | Where |
|---|---|
| Controller | `app/controllers/qi_reports_controller.rb` (`index`, `file`) |
| Filename parsing, visibility, divisions | `app/models/qi_report.rb` |
| View | `app/views/qi_reports/index.html.erb` |
| Routes | `qi_reports_path` (`/qi_reports`), `qi_report_file_path` (`/qi_reports/file`) |
| Nav link | `app/views/shared/_nav_bar.html.erb` |
| Specs | `spec/models/qi_report_spec.rb`, `spec/controllers/qi_reports_controller_spec.rb` |
| Report script | `script/qi_reports/` |

### Permissions

- PDFs live in `storage/qi_reports/`, **not** `public/` (files under `public/` are served without a login).
- Filenames must look like `<Report> - <District> - <date>.pdf`, for example
  `Titration - Sylhet - 2026-10-28.pdf` (month to date) or `Titration - Sylhet - Sep 2026.pdf` (finished month).
- A user sees a report only if its district name matches a district in
  `current_admin.accessible_district_regions(:view_reports)`. Power users see everything. A file whose
  district matches no known district is hidden from everyone except power users.
- PDFs are served by `QiReportsController#file` through `authorize`. The file parameter is matched against
  the user's permitted list, so a pasted URL for another district's file is refused and path traversal
  does not work.

### The report script (`script/qi_reports/`)

| File | Purpose |
|---|---|
| `publish_district_reports.py` | Builds the PDFs and publishes them. Run `--help`/read the docstring for flags. |
| `--settings-file` | The per-country settings as JSON: Metabase question numbers, filter and column names, wording, footer note, excluded places, place level. They live in `CountryConfig[:qi_reports][:script]` and are written by `bin/rails qi_reports:settings[PATH]` (`run_monthly.sh` does this for you). |
| `run_monthly.sh` | Production wrapper started by cron: `./run_monthly.sh <country>`. |
| `requirements.txt` | Python packages the script needs. |
| `settings.sh.example` | Names of the environment variables (`MB_URL`, `MB_KEY`), one `settings.<country>.sh` per country. Never commit real values. |
| `statins_all_districts.sql` | The Statins question's SQL changed to return all districts. Basis for a precomputed table. |

Dependencies: `pip install requests reportlab matplotlib`.

How it behaves:
- `--monthly` (production) = the last full month, 6 months of data. Without it, the run is the current month
  so far (used by the local prototype's daily run). `--month YYYY-MM` picks a specific month.
- Every district Metabase knows (`reporting_facilities`) minus the country's `exclude` list.
- Each publish **replaces** every older PDF for the same report and district (whatever its period), so only
  the latest report is kept.
- Publishing is **local-only** in the prototype: it copies PDFs into a folder (`QI_REPORTS_DIR`) and, for
  the local Docker setup, into the running container (`QI_COMPOSE_FILE`). See "For the engineer".
- A report that fails (for example a missing Statins CSV) is skipped with a warning; the others still run.
- The local prototype was scheduled with macOS launchd (daily, month to date). Production uses `run_monthly.sh`.

#### Titration headline fix

The Titration question returns an **"Average" row** (all districts) next to each district's rows. The
original script added every row for a month together, so the big headline % on each PDF mixed the
district with the national average (for one district it showed 7% when the district's own figure was
4.1%). The script now uses only the district's own rows for the headline, chart and table, and shows the
Average separately (dashed line, an "Average of all districts" note and a column). PDFs produced before
this fix have the wrong headline number.

### Statins

- Metabase question **1523** ("Statins by district, all districts") is the all-districts version of
  question 1129, saved in the same collection as the Titration question (997). Its date variable is
  `from_date`. The SQL is in `statins_all_districts.sql`.
- It takes **about 6 minutes** in the Metabase UI, but **more than 25 minutes** when requested through the
  API from the script (it was never seen to finish). The original 1129 timed out at 5 minutes per district.
  Possible causes are leftover queries from the early timed-out attempts still running on the database,
  or the API path being slower. Someone with database access should check `pg_stat_activity` for
  long-running queries from the API key before running it again, because this is the production reporting
  database.
- Because of that, Statins is built from **`statins.csv`**: run question 1523 in Metabase, download the
  results as CSV, and save it as `statins.csv` next to the script (or pass `--statins-csv`). The script
  reads Metabase's CSV formats (`May 1, 2026` or `2026-05-01` dates; `6,370` or `6370` numbers). Each
  Statins PDF says "Data from a Metabase download on <date>" and is dated with the CSV's save date.
- The API key's group must be able to read the question's collection; the first attempt returned 403 until
  the question was moved into the Titration collection.
- Statins covers NHF facilities only (the question's own filter), so it has fewer districts than Titration.

#### Recommended: precompute Statins

Question 1129/1523 recomputes everything from raw tables on every run (`cvd_risks` parsed with regular
expressions, `prescription_drugs`, ages recalculated per patient). Titration is fast because the
`titrated` flag is already calculated in the nightly-refreshed `reporting_patient_states` view.

Options, best first:
1. Add a materialized view (for example `reporting_statin_districts_per_month`) in `db/views`, refreshed in
   `RefreshReportingViews` with the other reporting views. Columns the script expects:
   `month_date`, `district`, `the_eligible_patients`, `statin_patients`, `percentage_statin_patients`
   (the script adds the Average itself, or keep an "Average" row). Then point a Metabase question, or the
   script, at it; the script change is small (re-add a card or SQL source for Statins).
2. Check whether `simple_reporting.reporting_patient_prescriptions` (has `prescribed_statins` and CVD risk
   score columns per patient per month, partitioned by `month_date`) is populated in production. If so,
   the Statins question could read it instead of the raw tables. Confirm the numbers match the current
   definition first.
3. Ask a Metabase admin whether question 1523 can have a **scheduled (nightly) cache**; then the script can
   call the card once and get the saved answer.

### Countries: Bangladesh and Ethiopia

Each country has its **own Metabase** (own address, API key and question numbers) and its **own app
deployment** (own storage, own scheduled run). The page code is shared; these differ:

| | Bangladesh | Ethiopia |
|---|---|---|
| Reports are per | district | **region** (state level) |
| Titration question | 997 | 255 |
| Place filter and column | `district_name` | `state_name` ("Select region") |
| Statins question | 1523 (all districts; 1129 per district) | 266 (per region) |
| Footer note on PDFs | NHF facilities only | RTSL facilities only |
| Metabase address | `https://metabase.bd.simple.org` | `https://simple.moh.gov.et/metabase` (note the `/metabase`) |
| Script settings | `CountryConfig` BD `qi_reports[:script]` | `CountryConfig` ET `qi_reports[:script]` |

Only these two countries are set up. Sri Lanka and any other deployment are not covered yet: a country
without settings uses the defaults (district-level reports, Division and District labels) and has no
script settings until some are added (see "Adding or changing a country's reports").

#### What the app does per country

`CountryConfig[:qi_reports]` (in `config/initializers/country_config.rb`) sets:
- `level`: `"district"` (default) or `"state"`. At `"state"` the page matches each PDF's name against the
  user's **state regions** (`accessible_state_regions(:view_reports)`, Simple's own rule: a user can view a
  state if they can manage a district in it) and shows one dropdown (no Division). At `"district"` it matches
  districts, as before. Only the configured level is matched, so a state and a district with the same name
  (for example Sylhet) cannot expose each other's reports.
- `division_label` / `place_label`: the dropdown labels. Bangladesh: Division / District. Ethiopia: Region.
  Other countries fall back to Division / District.

#### Adding or changing a country's reports

1. In that country's Metabase, make sure the question exists and note its number. The script fills these
   filters: the place filter, a start date and an end date (Titration, run once per month), and expects result
   columns for the place, month, the counted patients, the total and the percentage.
2. In `config/initializers/country_config.rb`, add a `script:` hash under that country's `qi_reports` (copy
   Bangladesh's) and edit the question numbers, filter names, column names, wording, `footer_note`,
   `exclude`, `place_noun` and the `place_list_sql` (the query listing the places to build).
3. Create `settings.<country>.sh` from `settings.sh.example` with that Metabase's address and API key, whose
   group must be able to read the questions' collection.
4. Test one place first, with that country's Metabase credentials loaded:
   `bin/rails qi_reports:settings[settings.json]` then
   `python3 script/qi_reports/publish_district_reports.py --settings-file settings.json --district "<place>" --dry-run`.
5. Run it on the schedule for that country's deployment and storage.

#### Ethiopia notes (from the screenshots of its Metabase)
- Reports are **per region only**. Titration (255) takes `state_name` ("Select region", a title-case value like
  `Addis Ababa`) plus start and end dates. The date filters are assumed to be called `start_date` and
  `end_date` (same as Bangladesh); if the script says a filter was not found, it lists the real names, so
  update the Ethiopia `script:` settings.
- Its Titration results had no "Average" row in the screenshot; the script copes without one.
- Statins (266) takes `From Date...` and a region (a lowercase slug like `addis-ababa`) and returns a
  `state` column plus "Average" rows. It will have the same speed question as Bangladesh's, but with about
  a dozen regions instead of ~50 districts. A region-level CSV is needed: either download it once per
  region and combine them, or ask for an all-regions version of the question (as was done for Bangladesh:
  `statins_all_districts.sql` is the Bangladesh example, which also has its `'nhf'` organisation filter).
  The CSV file name in the settings is `statins-ethiopia.csv`.
- Wording of the Ethiopia Statins description follows the question's title (diabetes aged 40+, stroke or heart
  attack history, or CV risk score of 10 or more).

### For the engineer

1. **Storage:** replace the `storage/qi_reports/` folder with durable shared storage (S3 or ActiveStorage)
   and change `publish_to_dashboard()` in the script to upload there. Keep the filenames and the
   "replace older month-to-date PDFs for the same report and district" rule. `QiReport::DIRECTORY` and
   `QiReport.all` are the app side.
2. **Run the script on a server** as a scheduled job instead of a laptop (it needs Metabase network access
   and `MB_KEY`).
3. **Match districts on a stable key** (region id or slug) instead of the district name in the filename.
4. **Statins data source:** see "Recommended: precompute Statins" above.
5. **Run the specs** (`bundle exec rspec spec/models/qi_report_spec.rb spec/controllers/qi_reports_controller_spec.rb`).
   They were written but never run: the authoring environment's Ruby (3.3) did not match the Gemfile (2.7.8).
6. The sample PDFs were removed from `storage/qi_reports/`; that folder is now only a `.keep` file and is
   a Capistrano linked directory.
7. The Metabase API keys are only in the PM's local `settings.<country>.sh` files; create proper service
   accounts and store the keys as secrets, one per country's Metabase.
8. **Per-country rollout:** each deployment needs the app code, its own durable storage for PDFs and its own
   scheduled run with that country's settings. For Capistrano deployments (`config/deploy/<country>`), note
   that `storage/` is not in `linked_dirs`, so PDFs saved under the release folder are lost on the next
   deploy; add `storage/qi_reports` to `linked_dirs` (single server) or use cloud storage (several servers),
   and remove the committed sample PDFs first.
9. Decide whether the QI tab should show in every deployment or only where reports exist (a feature flag).

### How to test permissions locally

1. Put some PDFs in `storage/qi_reports/` and rebuild the app image (see below).
2. Create a limited user in the Rails console (`docker compose -f .docker/docker-compose.yml exec server bundle exec rails console`):

   ```ruby
   fg = FacilityGroup.find_by!(name: "<a district that has PDFs>")
   user = User.new(full_name: "QI Viewer", role: "viewer", access_level: :viewer_all,
                   device_created_at: Time.current, device_updated_at: Time.current,
                   sync_approval_status: User.sync_approval_statuses[:denied])
   user.email_authentications.build(email: "qi-viewer@example.com", password: "Test-Password-12345-xyz")
   user.save!
   Access.create!(user: user, resource: fg)
   ```

   `viewer_all` sees the regular tabs; the access record limits them to that district.
3. Sign in as that user in a private window. They should see only that district on Reports (Hypertension and
   Diabetes tabs) and on the QI page, and a pasted file URL for another district should redirect with
   "You are not authorized to perform this action."
4. The Diabetes tab only appears if a facility in the district has `enable_diabetes_management: true`.
5. Districts created only from PDF names have no facilities, so their report pages are empty. To see
   numbers, rename a seeded district that has data.
6. Don't create two districts with the same name: access and the PDF matching go by name.

### Local development gotchas

- The local Docker setup **bakes the code and `storage/qi_reports/` into the image** (the compose volume does
  not mount the repo). After a pull or after adding PDFs, rebuild:
  `docker compose -f .docker/docker-compose.yml up -d --build server`. The script's `QI_COMPOSE_FILE`
  setting copies PDFs into the running container so they show without a rebuild, but they are lost on
  the next rebuild unless also in `storage/qi_reports/` (the `QI_REPORTS_DIR` copy).
- After a rebuild the server sometimes hangs on its first request. `docker compose -f .docker/docker-compose.yml restart server` fixes it.
- The "Prometheus Exporter, failed to send message … port 9394" errors in the logs and in the Rails console are
  noise from a metrics service that does not exist locally.
- Dashboards read from materialized views; after changing district names or data, refresh with
  `ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "false"; RefreshReportingViews.call` in the console.
