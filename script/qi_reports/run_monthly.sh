#!/usr/bin/env bash
# Monthly QI reports run, started by cron on the 3rd (see config/schedule.rb): ./run_monthly.sh <country>
# Builds last month's reports with 6 months of data, replacing the previous PDFs.
#
# Needs (all outside the repo):
#   $QI_SETTINGS_DIR/settings.<country>.sh   exports MB_URL and MB_KEY (see settings.sh.example)
#   python3 with script/qi_reports/requirements.txt installed (or set QI_PYTHON to a virtualenv's python)
#   $QI_REPORTS_DIR   where the app reads reports (default: the deployment's shared storage/qi_reports)
set -euo pipefail

COUNTRY="${1:-bangladesh}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED="${QI_SHARED_DIR:-/home/deploy/apps/simple-server/shared}"
SETTINGS="${QI_SETTINGS_DIR:-$SHARED/qi_reports}/settings.${COUNTRY}.sh"

if [ ! -f "$SETTINGS" ]; then
  echo "Missing $SETTINGS (it must export MB_URL and MB_KEY)" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$SETTINGS"

export QI_REPORTS_DIR="${QI_REPORTS_DIR:-$SHARED/storage/qi_reports}"

# The script writes its PDFs to ./output; use a scratch folder so releases stay clean
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

echo "=== $(date) ($COUNTRY, monthly) ==="
"${QI_PYTHON:-python3}" "$SCRIPT_DIR/publish_district_reports.py" --country "$COUNTRY" --monthly
