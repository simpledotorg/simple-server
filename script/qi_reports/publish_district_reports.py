"""
Daily district reports -> one PDF per district per report -> the Simple dashboard's QI reports tab.

Reports (see REPORTS below):
  Titration  Metabase question 997, run per district per month.
  Statins    Built from statins.csv, the results of Metabase question 1523 downloaded by hand. That
             question takes about 6 minutes in Metabase and over 25 minutes through the API, so it is
             not run from this script. See doc/qi_reports_handoff.md.

Each PDF is named "<Report> - <District> - <date>.pdf" (the QI page parses this name for permissions)
and published to the QI reports page. Nothing is emailed.

By default it reports the current month so far (1st of this month to today). Each run replaces the
previous month-to-date PDFs for the same report and district, so the page doesn't fill up with one
file per day. Reports for a finished month (--month) are kept. Statins PDFs are dated with the day the
CSV was saved, and say so on the page.

Usage:
  python publish_district_reports.py                  # all reports, month to date, publish
  python publish_district_reports.py --dry-run        # build PDFs into ./output, don't publish
  python publish_district_reports.py --month 2026-09  # a finished month (kept, never replaced)
  python publish_district_reports.py --reports Titration            # only some reports
  python publish_district_reports.py --district "Sylhet" --dry-run  # test one district
  python publish_district_reports.py --statins-csv path/to/file.csv # CSV from Metabase question 1523
  python publish_district_reports.py --publish-only   # publish PDFs already in ./output

Environment variables:
  MB_URL, MB_KEY      Metabase address and API key (Titration needs them; a Statins-only run does not)
  STATINS_CSV         path to the Statins CSV (default: statins.csv in the current folder)
  QI_REPORTS_DIR      folder the app reads reports from, e.g. ~/simple-server/storage/qi_reports
  QI_COMPOSE_FILE     (local Docker only) e.g. ~/simple-server/.docker/docker-compose.yml. Also copies the
                      PDFs into the running app container so they show up without a rebuild.
"""

import argparse
import calendar
import csv
import glob
import io
import os
import re
import shutil
import subprocess
import sys
from datetime import date, datetime

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker
import requests
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import HRFlowable, Image, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

# ---------------------------------------------------------------- settings
REPORTS = [
    {
        "name": "Titration", "card_id": 997,
        # Filter names on the Metabase question
        "district_filter": "district_name", "start_filter": "start_date", "end_filter": "end_date",
        # True: run the question once per month (it takes a start and an end date)
        "per_month": True, "lowercase_district": False,
        # Result columns
        "district_col": "district_name", "month_col": "month_date",
        "numerator_col": "titrated", "denominator_col": "uncontrolled", "percent_col": "percent_titrated",
        # Wording on the PDF
        "headline": "% of uncontrolled patients titrated",
        "description": "Hypertension patients with uncontrolled BP whose treatment was intensified during the month",
        "numerator_label": "Titrated", "denominator_label": "Uncontrolled",
        "sentence": "{num} patients titrated<br/>of {den} patients with uncontrolled BP in {month}",
    },
    {
        "name": "Statins", "csv": "statins.csv",
        # Metabase question 1523 takes too long to run from the script, so this report is built from
        # its results downloaded as a CSV from Metabase (see --statins-csv).
        "district_col": "district", "month_col": "month_date",
        "numerator_col": "statin_patients", "denominator_col": "the_eligible_patients",
        "percent_col": "percentage_statin_patients",
        "headline": "% of eligible patients prescribed statins",
        "description": "Patients eligible for statins who have been prescribed a statin",
        "numerator_label": "On statins", "denominator_label": "Eligible",
        "sentence": "{num} patients prescribed statins<br/>of {den} eligible patients in {month}",
    },
]

# How many months each report covers (the reporting month plus the months before it)
MONTHS = 6

# Where the district list comes from. Check the column name matches your table.
DISTRICT_LIST_SQL = """
SELECT DISTINCT district_name
FROM reporting_facilities
WHERE district_name IS NOT NULL
ORDER BY 1
"""

# Districts to leave out of the reports (test or placeholder districts)
EXCLUDE_DISTRICTS = ["Temp District"]

MB_URL = os.environ.get("MB_URL", "").rstrip("/")
MB_KEY = os.environ.get("MB_KEY", "").strip()


# ---------------------------------------------------------------- Metabase
def mb(method, path, timeout=300, **kwargs):
    resp = requests.request(
        method, f"{MB_URL}/api{path}",
        headers={"X-API-Key": MB_KEY, "Content-Type": "application/json"},
        timeout=timeout, **kwargs,
    )
    if resp.status_code >= 400:
        sys.exit(f"Metabase error {resp.status_code} on {method} {path}:\n{resp.text[:1000]}")
    data = resp.json()
    if isinstance(data, dict) and data.get("error"):
        sys.exit(f"Metabase query error on {path}:\n{data['error']}")
    return data


def find_param(card, name):
    """Find a question's filter by its variable name (matches slug or display name)."""
    want = name.lower()
    for p in card.get("parameters", []):
        target = p.get("target") or []
        tag = target[1][1] if len(target) > 1 and isinstance(target[1], list) else None
        if want in {str(p.get("slug", "")).lower(), str(p.get("name", "")).lower(), str(tag).lower()}:
            return p
    names = [p.get("slug") for p in card.get("parameters", [])]
    sys.exit(f"Filter '{name}' not found on question {card['id']}. Filters found: {names}")


def param_value(p, value):
    # Field filters ("dimension") expect a list of values; plain variables take a single value
    is_field_filter = (p.get("target") or [None])[0] == "dimension"
    return {"id": p["id"], "type": p["type"], "target": p["target"],
            "value": [value] if is_field_filter else value}


def run_report(spec, card, district, start, end):
    value = district.lower() if spec["lowercase_district"] else district
    params = [
        param_value(find_param(card, spec["district_filter"]), value),
        param_value(find_param(card, spec["start_filter"]), start.isoformat()),
    ]
    if spec["end_filter"]:
        params.append(param_value(find_param(card, spec["end_filter"]), end.isoformat()))
    result = mb("POST", f"/card/{card['id']}/query", json={"parameters": params})
    cols = [c.get("display_name") or c["name"] for c in result["data"]["cols"]]
    return cols, result["data"]["rows"]


def run_report_by_month(spec, card, district, start, end):
    """Per-month questions: run once per month from start to end and combine the rows,
    adding a month column if the question doesn't return one."""
    cols, all_rows = None, []
    month_start = start
    while month_start <= end:
        last_day = date(month_start.year, month_start.month,
                        calendar.monthrange(month_start.year, month_start.month)[1])
        month_end = min(last_day, end)
        c, rows = run_report(spec, card, district, month_start, month_end)
        if spec["month_col"] not in norm(c):
            c = [spec["month_col"]] + c
            rows = [[month_start.isoformat()] + list(r) for r in rows]
        cols = c
        all_rows += rows
        month_start = add_months(month_start, 1)
    return cols, all_rows


def parse_month(value):
    """Metabase CSVs can hold dates as 2026-05-01, 2026-05-01T00:00:00Z or 'May 1, 2026'."""
    v = str(value).strip().strip('"')
    m = re.match(r"(\d{4})-(\d{2})", v)
    if m:
        return f"{m.group(1)}-{m.group(2)}"
    for fmt in ("%B %d, %Y", "%b %d, %Y", "%B %Y", "%b %Y"):
        try:
            return datetime.strptime(v, fmt).strftime("%Y-%m")
        except ValueError:
            pass
    sys.exit(f"Can't read the date '{value}' in the CSV. Expected something like 2026-05-01 or May 1, 2026.")


def parse_number(value):
    v = str(value).strip().strip('"').replace(",", "").replace("%", "")
    if v == "" or v.lower() in ("null", "none", "nan"):
        return None
    try:
        return float(v)
    except ValueError:
        sys.exit(f"Can't read the number '{value}' in the CSV.")


def load_csv(spec, path, start, end):
    """Read a results CSV downloaded from Metabase; returns (columns, rows) for the reporting window,
    with months as YYYY-MM and numbers as numbers."""
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.reader(fh)
        header = next(reader, None)
        if not header:
            sys.exit(f"{path} is empty.")
        cols = [h.strip() for h in header]
        lower = norm(cols)
        need = ["district_col", "month_col", "numerator_col", "denominator_col", "percent_col"]
        missing = [spec[k] for k in need if spec[k] not in lower]
        if missing:
            sys.exit(f"{path}: column(s) {missing} not found. Columns in the file: {lower}")
        di, mi, ni, ei, pi = (lower.index(spec[k]) for k in need)
        first, last = start.strftime("%Y-%m"), end.strftime("%Y-%m")
        rows = []
        for r in reader:
            if not r or len(r) < len(cols) or not r[mi].strip():
                continue
            month = parse_month(r[mi])
            if not first <= month <= last:
                continue
            row = list(r)
            row[mi], row[di] = month, r[di].strip()
            for i in (ni, ei):  # patient counts are whole numbers
                n = parse_number(r[i])
                row[i] = None if n is None else int(round(n))
            row[pi] = parse_number(r[pi])
            rows.append(row)
    return cols, rows


def fetch_report(spec, card, district, start, end):
    if spec["per_month"]:
        return run_report_by_month(spec, card, district, start, end)
    cols, rows = run_report(spec, card, district, start, end)
    mi = norm(cols).index(spec["month_col"]) if spec["month_col"] in norm(cols) else None
    if mi is not None:  # keep only the months in the reporting window
        first, last = start.strftime("%Y-%m"), end.strftime("%Y-%m")
        rows = [r for r in rows if r[mi] is not None and first <= str(r[mi])[:7] <= last]
    return cols, rows


def list_districts(database_id):
    result = mb("POST", "/dataset", json={
        "database": database_id, "type": "native", "native": {"query": DISTRICT_LIST_SQL}})
    return [r[0] for r in result["data"]["rows"] if r[0]]


# ---------------------------------------------------------------- PDF
def fmt(v):
    if v is None:
        return ""
    if isinstance(v, float):
        return f"{v:,.2f}"
    if isinstance(v, int):
        return f"{v:,}"
    s = str(v)
    return s[:10] if re.match(r"\d{4}-\d{2}-\d{2}T", s) else s


def norm(cols):
    return [c.lower().replace(" ", "_") for c in cols]


def find_col(lower, exact, contains, avoid=()):
    if exact in lower:
        return lower.index(exact)
    for i, c in enumerate(lower):
        if contains in c and not any(x in c for x in avoid):
            return i
    return None


def metric_series(spec, cols, rows, district):
    """Per month, newest first: (month, numerator, denominator, % for the district, % average).

    The questions also return an "Average" row (all districts) for each month. Only the district's
    own rows feed the headline, table and chart; the Average row is shown as a comparison."""
    lower = norm(cols)
    need = ["district_col", "month_col", "numerator_col", "denominator_col", "percent_col"]
    missing = [spec[k] for k in need if spec[k] not in lower]
    if missing:
        sys.exit(f"{spec['name']}: column(s) {missing} not found in the results. Columns found: {lower}")
    di, mi, ni, ei, pi = (lower.index(spec[k]) for k in need)

    def pct(row):
        if row[pi] is not None:
            return float(row[pi])
        return round(100 * row[ni] / row[ei], 2) if row[ei] else None

    months = {}
    for r in rows:
        if r[mi] is None:
            continue
        month, name = str(r[mi])[:7], str(r[di] or "").strip().lower()
        entry = months.setdefault(month, {"district": None, "average": None})
        if name == district.strip().lower():
            entry["district"] = (r[ni] or 0, r[ei] or 0, pct(r))
        elif name == "average":
            entry["average"] = pct(r)
    out = []
    for month in sorted(months, reverse=True):
        d = months[month]["district"]
        if d is not None:
            out.append((month, d[0], d[1], d[2], months[month]["average"]))
    return out


def month_label(ym):
    return date(int(ym[:4]), int(ym[5:7]), 1).strftime("%b %Y")


# ---- look and feel (Simple dashboard style)
BLUE = "#0075eb"
DARK = "#2f363d"
MUTED = "#5f6770"
LINE = "#dde1e6"
SOFT_BLUE = "#e0f0ff"
PAGE_W, PAGE_H = A4
MARGIN = 1.6 * cm
CONTENT_W = PAGE_W - 2 * MARGIN


def styles_for_pdf():
    base = getSampleStyleSheet()
    s = {}
    s["title"] = ParagraphStyle("title", parent=base["Normal"], fontName="Helvetica-Bold",
                                fontSize=26, leading=30, textColor=colors.HexColor(DARK))
    s["subtitle"] = ParagraphStyle("subtitle", parent=base["Normal"], fontName="Helvetica-Bold",
                                   fontSize=10.5, leading=14, textColor=colors.HexColor(DARK))
    s["label"] = ParagraphStyle("label", parent=base["Normal"], fontName="Helvetica-Bold",
                                fontSize=8, leading=10, textColor=colors.HexColor(DARK))
    s["h2"] = ParagraphStyle("h2", parent=base["Normal"], fontName="Helvetica-Bold",
                             fontSize=13, leading=16, textColor=colors.HexColor(DARK))
    s["body"] = ParagraphStyle("body", parent=base["Normal"], fontName="Helvetica",
                               fontSize=9, leading=12.5, textColor=colors.HexColor(DARK))
    s["muted"] = ParagraphStyle("muted", parent=s["body"], textColor=colors.HexColor(MUTED))
    s["big"] = ParagraphStyle("big", parent=base["Normal"], fontName="Helvetica-Bold",
                              fontSize=30, leading=34, textColor=colors.HexColor(DARK))
    return s


def section_label(text, st):
    # Letter-spaced uppercase label, like PROGRAM OVERVIEW on the dashboard
    return Paragraph(" ".join(text.upper()).replace("   ", " &nbsp; "), st["label"])


def card(flowables, padding=14):
    """A bordered box around a list of flowables."""
    t = Table([[flowables]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.8, colors.HexColor(DARK)),
        ("LEFTPADDING", (0, 0), (-1, -1), padding), ("RIGHTPADDING", (0, 0), (-1, -1), padding),
        ("TOPPADDING", (0, 0), (-1, -1), padding), ("BOTTOMPADDING", (0, 0), (-1, -1), padding),
    ]))
    return t


def to_image(fig, width):
    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=200, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    buf.seek(0)
    img = Image(buf)
    img.drawWidth, img.drawHeight = width, width * img.imageHeight / img.imageWidth
    return img


def style_axes(ax):
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(LINE)
    ax.tick_params(colors=MUTED, labelsize=8, length=0)
    ax.yaxis.grid(True, color="#eef0f2", linewidth=0.8)
    ax.set_axisbelow(True)


def trend_chart(series, partial_last):
    """Line chart of the district's % per month (oldest to newest), with the all-district
    average as a dashed grey line when the question provides it."""
    data = [(m, p, a) for m, _, _, p, a in reversed(series) if p is not None]
    if not data:
        return None
    labels = [month_label(m) for m, _, _ in data]
    if partial_last:
        labels[-1] += "*"
    values = [p for _, p, _ in data]
    averages = [a for _, _, a in data]
    x = list(range(len(values)))
    fig, ax = plt.subplots(figsize=(7.2, 2.6))
    ax.fill_between(x, values, color=SOFT_BLUE)
    if any(a is not None for a in averages):
        ax.plot([xi for xi, a in zip(x, averages) if a is not None], [a for a in averages if a is not None],
                color=MUTED, linewidth=1.4, linestyle="--", label="Average of all districts")
        ax.legend(frameon=False, fontsize=8, loc="upper left", labelcolor=MUTED)
    ax.plot(x, values, color=BLUE, linewidth=2, marker="o", markersize=6,
            markerfacecolor="white", markeredgecolor=BLUE, markeredgewidth=1.8)
    for xi, v in zip(x, values):
        ax.annotate(f"{v:.0f}%", (xi, v), textcoords="offset points", xytext=(0, 9),
                    ha="center", fontsize=8.5, color=DARK, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    top = max([v for v in values] + [a for a in averages if a is not None])
    ax.set_ylim(0, max(top * 1.35, 10))
    ax.yaxis.set_major_locator(matplotlib.ticker.MaxNLocator(5, integer=True))
    ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f"{v:.0f}%"))
    ax.margins(x=0.04)
    style_axes(ax)
    return to_image(fig, CONTENT_W - 28)


def data_table(header, rows, highlight_first=False, col_widths=None):
    t = Table([header] + rows, repeatRows=1, colWidths=col_widths)
    style = [
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8.5),
        ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor(DARK)),
        ("LINEBELOW", (0, 0), (-1, 0), 0.8, colors.HexColor(DARK)),
        ("LINEBELOW", (0, 1), (-1, -1), 0.4, colors.HexColor("#eef0f2")),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
        ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    if highlight_first and rows:
        style += [("BACKGROUND", (0, 1), (-1, 1), colors.HexColor(SOFT_BLUE)),
                  ("FONTNAME", (0, 1), (-1, 1), "Helvetica-Bold")]
    t.setStyle(TableStyle(style))
    return t


def build_pdf(path, spec, district, period, series, partial_last=False, data_note=None):
    st = styles_for_pdf()
    report_name = spec["name"]
    generated = date.today().strftime("%-d %b %Y")

    def decorate(canv, doc):
        canv.saveState()
        canv.setStrokeColor(colors.HexColor(LINE))
        canv.line(MARGIN, 1.2 * cm, PAGE_W - MARGIN, 1.2 * cm)
        canv.setFont("Helvetica", 7.5)
        canv.setFillColor(colors.HexColor(MUTED))
        canv.drawString(MARGIN, 0.8 * cm,
                        f"{report_name} report · {district} · Source: Simple (Metabase) · NHF facilities only")
        canv.drawRightString(PAGE_W - MARGIN, 0.8 * cm, f"Generated {generated} · Page {doc.page}")
        canv.restoreState()

    doc = SimpleDocTemplate(path, pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN,
                            topMargin=MARGIN, bottomMargin=1.8 * cm,
                            title=f"{report_name} - {district} - {period}", author="Resolve to Save Lives")
    story = [Paragraph(district, st["title"]), Spacer(1, 4),
             Paragraph(f"{report_name} report · {period}", st["subtitle"]), Spacer(1, 6),
             HRFlowable(width="100%", thickness=0.8, color=colors.HexColor(LINE)), Spacer(1, 16),
             section_label(report_name, st), Spacer(1, 8)]

    if not series:
        story.append(card([Paragraph("No data for this district in this period.", st["body"])]))
        doc.build(story, onFirstPage=decorate, onLaterPages=decorate)
        return

    latest_m, latest_n, latest_d, latest_p, latest_avg = series[0]
    latest_label = month_label(latest_m) + (" (month to date)" if partial_last else "")
    headline = [Paragraph(spec["headline"], st["h2"]), Spacer(1, 3),
                Paragraph(spec["description"], st["muted"]), Spacer(1, 10),
                Paragraph(f"{latest_p:.0f}%" if latest_p is not None else "–", st["big"]),
                Paragraph(spec["sentence"].format(num=fmt(latest_n), den=fmt(latest_d), month=latest_label),
                          st["body"])]
    notes = []
    if len(series) > 1 and series[1][3] is not None and latest_p is not None:
        diff = round(latest_p - series[1][3], 1)
        word = "Up" if diff > 0 else "Down"
        notes.append(f"{word} {abs(diff):.1f} points from {month_label(series[1][0])}" if diff
                     else f"No change from {month_label(series[1][0])}")
    if latest_avg is not None:
        notes.append(f"Average of all districts: {latest_avg:.1f}%")
    if data_note:
        notes.append(data_note)
    if notes:
        headline += [Spacer(1, 4), Paragraph("<br/>".join(notes), st["muted"])]
    img = trend_chart(series, partial_last)
    if img:
        headline += [Spacer(1, 12), img]
    if partial_last:
        headline += [Spacer(1, 4), Paragraph("* Current month so far; numbers will change "
                                             "until the month ends.", st["muted"])]
    story += [card(headline), Spacer(1, 14)]

    has_avg = any(row[4] is not None for row in series)
    header = ["Month", spec["denominator_label"], spec["numerator_label"], "%"]
    widths = [0.28, 0.22, 0.22, 0.14]
    if has_avg:
        header.append("Average %")
        widths.append(0.14)
    else:
        widths = [0.34, 0.22, 0.22, 0.22]
    body = []
    for m, n, d, p_, a in series:
        row = [month_label(m), fmt(d), fmt(n), f"{p_:.1f}%" if p_ is not None else "–"]
        if has_avg:
            row.append(f"{a:.1f}%" if a is not None else "–")
        body.append(row)
    story += [card([Paragraph("By month", st["h2"]), Spacer(1, 8),
                    data_table(header, body, highlight_first=True,
                               col_widths=[w * (CONTENT_W - 28) for w in widths])])]
    doc.build(story, onFirstPage=decorate, onLaterPages=decorate)


# ---------------------------------------------------------------- dashboard
DATED = re.compile(r"\A(?P<report>.+?) - (?P<district>.+) - \d{4}-\d{2}-\d{2}\.pdf\Z")


def stale_month_to_date(existing, new_files):
    """Old month-to-date PDFs (…- YYYY-MM-DD.pdf) for a report+district that has a new one."""
    keys = set()
    for f in new_files:
        m = DATED.match(f)
        if m:
            keys.add((m["report"], m["district"]))
    stale = []
    for f in existing:
        m = DATED.match(f)
        if m and (m["report"], m["district"]) in keys and f not in new_files:
            stale.append(f)
    return stale


def publish_to_dashboard(files):
    """Put the PDFs where the Simple dashboard's QI reports tab reads them, replacing older
    month-to-date PDFs for the same districts.

    The tab lists files named "<Report> - <District> - <date>.pdf" and only shows each one to
    users with access to that district, so keep the file names exactly as built above.

    FOR THE ENGINEER: this is the local-only version (copy into a folder, plus docker cp into the dev
    container). In production, replace the body with an upload to wherever the server reads reports
    from (S3 / shared storage / an upload endpoint), with the same replace-old-month-to-date rule.
    Keep the file names unchanged.
    """
    target = os.environ.get("QI_REPORTS_DIR", "").strip()
    compose = os.environ.get("QI_COMPOSE_FILE", "").strip()
    if not target and not compose:
        print("Not published to the dashboard: set QI_REPORTS_DIR (and QI_COMPOSE_FILE for local Docker).")
        return False
    names = [os.path.basename(f) for f in files]

    if target:
        target = os.path.expanduser(target)
        os.makedirs(target, exist_ok=True)
        for old in stale_month_to_date(os.listdir(target), names):
            os.remove(os.path.join(target, old))
        for f in files:
            shutil.copy2(f, os.path.join(target, os.path.basename(f)))
        print(f"Copied {len(files)} PDF(s) to {target}")

    if compose:
        compose = os.path.expanduser(compose)
        base = ["docker", "compose", "-f", compose]
        listing = subprocess.run(base + ["exec", "-T", "server", "ls", "/opt/app/storage/qi_reports"],
                                 capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if listing.returncode != 0:
            print(f"Could not reach the app container (is it running?):\n{listing.stderr.strip()[:500]}")
            return False
        for old in stale_month_to_date(listing.stdout.splitlines(), names):
            subprocess.run(base + ["exec", "-T", "server", "rm", "-f", "--",
                                   f"/opt/app/storage/qi_reports/{old}"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
        for f in files:
            result = subprocess.run(base + ["cp", f, "server:/opt/app/storage/qi_reports/"],
                                    capture_output=True, text=True, stdin=subprocess.DEVNULL)
            if result.returncode != 0:
                print(f"Could not copy {os.path.basename(f)} into the app container:\n{result.stderr.strip()[:500]}")
                return False
        print(f"Copied {len(files)} PDF(s) into the running app container")
    return True


# ---------------------------------------------------------------- main
def add_months(d, n):
    """First day of the month n months after d's month (n can be negative)."""
    total = d.year * 12 + d.month - 1 + n
    return date(total // 12, total % 12 + 1, 1)


def previous_month(today):
    y, m = (today.year, today.month - 1) if today.month > 1 else (today.year - 1, 12)
    return y, m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--month", help="YYYY-MM for a finished month (default: the current month so far)")
    ap.add_argument("--district", help="Only run for this district (for testing)")
    ap.add_argument("--limit", type=int, help="Only the first N districts (for testing)")
    ap.add_argument("--dry-run", action="store_true", help="Build PDFs but don't publish them")
    ap.add_argument("--reports", help="Only these reports, comma-separated, e.g. Titration (default: all)")
    ap.add_argument("--statins-csv", help="CSV of Metabase question 1523's results "
                    "(default: $STATINS_CSV, or statins.csv in this folder)")
    ap.add_argument("--publish-only", action="store_true",
                    help="Don't rebuild: publish the PDFs already in ./output for this run's date")
    args = ap.parse_args()

    if not args.month:
        end = date.today()
        last_month_start = end.replace(day=1)
        end_label = f"{end:%B} {end.day}, {end.year}"
        file_date = end.strftime("%Y-%m-%d")
    else:
        y, m = map(int, args.month.split("-"))
        last_month_start = date(y, m, 1)
        end = date(y, m, calendar.monthrange(y, m)[1])
        end_label = end.strftime("%B %Y")
        file_date = end.strftime("%b %Y")
    start = add_months(last_month_start, -(MONTHS - 1))
    period = f"{start:%B %Y} to {end_label}"

    wanted = {n.strip().lower() for n in args.reports.split(",")} if args.reports else None
    specs = [r for r in REPORTS if wanted is None or r["name"].lower() in wanted]
    if not specs:
        sys.exit(f"No report matches --reports {args.reports}. Reports: {[r['name'] for r in REPORTS]}")

    # Reports built from a downloaded CSV take the CSV's date (that is how fresh their data is)
    csv_paths, file_dates = {}, {}
    for spec in specs:
        if spec.get("csv"):
            path = args.statins_csv or os.environ.get("STATINS_CSV") or spec["csv"]
            path = os.path.expanduser(path)
            if not os.path.isfile(path):
                print(f"WARNING: {spec['name']} skipped: no CSV at {path} "
                      f"(download question 1523's results from Metabase and save it there)")
                continue
            csv_paths[spec["name"]] = path
            saved = datetime.fromtimestamp(os.path.getmtime(path))
            file_dates[spec["name"]] = file_date if args.month else saved.strftime("%Y-%m-%d")
    specs = [s_ for s_ in specs if not s_.get("csv") or s_["name"] in csv_paths]
    if not specs:
        sys.exit("Nothing to build.")

    if args.publish_only:
        dates = {file_date} | set(file_dates.values())
        files = sorted(f for d in dates for f in glob.glob(os.path.join("output", f"* - {d}.pdf")))
        if not files:
            sys.exit(f"No PDFs ending in {sorted(dates)} in ./output")
        print(f"Publishing {len(files)} existing PDF(s)")
        if not publish_to_dashboard(files):
            sys.exit("Not published.")
        print(f"Published {len(files)} PDF(s) to the QI reports page")
        return

    card_specs = [s_ for s_ in specs if s_.get("card_id")]
    if card_specs and (not MB_URL or not MB_KEY):
        sys.exit("Set MB_URL and MB_KEY environment variables first.")
    cards = [(s_, mb("GET", f"/card/{s_['card_id']}")) for s_ in card_specs]
    shared = {name: load_csv(next(s_ for s_ in specs if s_["name"] == name), path, start, end)
              for name, path in csv_paths.items()}

    if args.district:
        districts = [args.district]
    elif cards:
        districts = list_districts(cards[0][1]["database_id"])
    else:  # CSV-only run: the districts are the ones in the file
        cols0, rows0 = next(iter(shared.values()))
        spec0 = next(s_ for s_ in specs if s_["name"] in shared)
        di0 = norm(cols0).index(spec0["district_col"])
        districts = sorted({str(r[di0]).strip() for r in rows0 if str(r[di0]).strip().lower() != "average"})
    districts = [d for d in districts if d not in EXCLUDE_DISTRICTS]
    if args.limit:
        districts = districts[:args.limit]
    print(f"{period}: {len(districts)} district(s)")

    os.makedirs("output", exist_ok=True)
    card_by_name = {s_["name"]: c for s_, c in cards}
    files = []
    for spec in specs:
        name = spec["name"]
        note = None
        if name in csv_paths:
            saved = datetime.fromtimestamp(os.path.getmtime(csv_paths[name]))
            note = f"Data from a Metabase download on {saved:%-d %b %Y}"
        for district in districts:
            if name in shared:
                cols, rows = shared[name]
            else:
                cols, rows = fetch_report(spec, card_by_name[name], district, start, end)
            series = metric_series(spec, cols, rows, district)
            safe = re.sub(r'[\\/:*?"<>|]', "-", district)
            path = os.path.join("output", f"{name} - {safe} - {file_dates.get(name, file_date)}.pdf")
            build_pdf(path, spec, district, period, series, partial_last=not args.month, data_note=note)
            files.append(path)
            print(f"  built {path}")

    if args.dry_run:
        print("Dry run: not published. PDFs are in ./output")
        return
    if publish_to_dashboard(files):
        print(f"Published {len(files)} PDF(s) to the QI reports page")
    else:
        sys.exit("Not published. The PDFs are in ./output")


if __name__ == "__main__":
    main()
