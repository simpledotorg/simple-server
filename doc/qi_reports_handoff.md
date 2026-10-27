# QI reports page: handoff notes

**What it does:** `/resources/qi_reports` lists district PDFs produced by `send_district_reports.py`
(Metabase question 997 → one PDF per district per month) with an inline viewer, Download and Print.

## How permissions work (prototype)
- PDFs live in `storage/qi_reports/`, **not** `public/` (public files are served with no login).
- Filenames must look like `Titration - <District> - Sep 2026.pdf` (the script already does this;
  month-to-date runs use `... - 2026-10-27.pdf`). `QiReport` parses them.
- A user sees a report only if its district name matches one of
  `current_admin.accessible_district_regions(:view_reports)`. Power users see everything.
  Unmatched district names are hidden.
- PDFs are served by `ResourcesController#qi_report` through `authorize`, so a pasted URL for another
  district's file is refused. The file param is matched against the permitted list (no path traversal).

## For the engineer to do
1. Replace the folder with durable storage (S3 / ActiveStorage) and have the script upload there
   (or run it as a scheduled job on the server), instead of copying files into `storage/qi_reports/`.
2. Match on a stable key (district region id/slug) rather than the district name in the filename.
3. Decide whether to keep or drop the `*Sample District*` sample files.
4. Local Docker bakes code into the image, so rebuild after adding PDFs:
   `docker compose -f .docker/docker-compose.yml up -d --build server`.

Specs: `spec/models/qi_report_spec.rb`, `spec/controllers/resources_controller_spec.rb`
(written but not yet run: the authoring environment's Ruby didn't match the Gemfile).
