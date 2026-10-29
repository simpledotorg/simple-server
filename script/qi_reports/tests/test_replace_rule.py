"""Run with: python3 script/qi_reports/tests/test_replace_rule.py (needs requests, reportlab, matplotlib)."""
import importlib.util
import os

os.environ.setdefault("MB_URL", "http://example")
os.environ.setdefault("MB_KEY", "key")
path = os.path.join(os.path.dirname(__file__), "..", "publish_district_reports.py")
spec = importlib.util.spec_from_file_location("publish_district_reports", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

existing = [
    "Titration - Sylhet - Sep 2026.pdf",
    "Titration - Sylhet - 2026-10-28.pdf",
    "Titration - Dhaka - Aug 2026.pdf",
    "Statins - Sylhet - 2026-10-28.pdf",
    "notes.txt",
    "Titration - Sylhet - Oct 2026.pdf",
]
stale = sorted(module.stale_reports(existing, ["Titration - Sylhet - Oct 2026.pdf"]))
# the new report replaces older ones for the same report and district, whatever the period format,
# and leaves other districts, other reports and other files alone
assert stale == ["Titration - Sylhet - 2026-10-28.pdf", "Titration - Sylhet - Sep 2026.pdf"], stale
assert module.stale_reports(existing, []) == []
print("ok")
