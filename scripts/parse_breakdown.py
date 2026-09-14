#!/usr/bin/env python3
"""Extract the per-widget-type rebuild breakdown from a debug benchmark run log.

The FrameworkRebuildTracker (active only in debug builds) prints one summary
line per (library, event):

    [riverpod/load_page_1] rebuilds=11 {RiverpodUserListPage: 1, RiverpodUserCard: 10}

These counts are NOT serialized into benchmark_*.csv/json (which carry only the
aggregate rebuild_count). This script parses them out of the run log and writes
two tidy CSVs:

  breakdown_by_type.csv   library,event,widget_type,rebuild_count   (long form)
  breakdown_summary.csv   library,event,list_page,card,total        (wide form)

The summary classifies each widget type as the list page (…ListPage / …Page) or
the card (…Card), which maps directly to the §6.2.2.1 breakdown table.

Usage:
    python3 scripts/parse_breakdown.py [run-log] [out-dir]
    python3 scripts/parse_breakdown.py runs/advanced/breakdown_light.log \
        results/new-runs/advanced/light
"""
import csv
import os
import re
import sys

LINE = re.compile(r"\[(\w+)/(\w+)\]\s+rebuilds=(\d+)\s+\{([^}]*)\}")
LIB_ORDER = {"provider": 0, "riverpod": 1, "getx": 2, "watch_it": 3}
EVENT_ORDER = {
    "load_page_1": 0, "add_user": 1, "edit_user": 2, "delete_user": 3,
    "search_query": 4, "search_clear": 5, "load_page_2": 6, "load_page_3": 7,
}


def classify(widget_type):
    if widget_type.endswith("Card"):
        return "card"
    if widget_type.endswith("Page"):
        return "list_page"
    return "other"


def main():
    log = sys.argv[1] if len(sys.argv) > 1 else \
        "runs/advanced/breakdown_light.log"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else \
        "results/new-runs/advanced/light"

    # (library, event) -> {widget_type: count}. Deterministic, so dedupe by key.
    rows = {}
    with open(log, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            m = LINE.search(raw)
            if not m:
                continue
            lib, event, total, body = m.groups()
            types = {}
            for part in (p.strip() for p in body.split(",") if p.strip()):
                if ":" not in part:
                    continue
                name, n = part.rsplit(":", 1)
                types[name.strip()] = int(n.strip())
            rows[(lib, event)] = (int(total), types)

    if not rows:
        print(f"No breakdown lines found in {log} "
              f"(was the run done in DEBUG mode?).")
        sys.exit(1)

    os.makedirs(out_dir, exist_ok=True)
    ordered = sorted(rows, key=lambda k: (LIB_ORDER.get(k[0], 9),
                                          EVENT_ORDER.get(k[1], 9)))

    by_type = os.path.join(out_dir, "breakdown_by_type.csv")
    with open(by_type, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["library", "event", "widget_type", "rebuild_count"])
        for key in ordered:
            lib, event = key
            _, types = rows[key]
            if not types:
                w.writerow([lib, event, "(none)", 0])
            for name, n in sorted(types.items()):
                w.writerow([lib, event, name, n])

    summary = os.path.join(out_dir, "breakdown_summary.csv")
    with open(summary, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["library", "event", "list_page", "card", "total"])
        for key in ordered:
            lib, event = key
            total, types = rows[key]
            page = sum(v for k, v in types.items() if classify(k) == "list_page")
            card = sum(v for k, v in types.items() if classify(k) == "card")
            w.writerow([lib, event, page, card, total])

    print(f"✓ {by_type}  ({sum(len(t) or 1 for _, t in rows.values())} rows)")
    print(f"✓ {summary}  ({len(rows)} rows)")


if __name__ == "__main__":
    main()
