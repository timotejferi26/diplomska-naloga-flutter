#!/usr/bin/env python3
"""Cross-preset comparison charts (how metrics scale with dataset size).

Reads each preset's aggregated.csv under a results dir and draws one line per
library across presets ordered by dataset size (none=0, light=100, medium=1000,
heavy=5000).

Usage:
    python3 scripts/generate_preset_charts.py [results-dir] [out-dir]
    python3 scripts/generate_preset_charts.py results/advanced figures/advanced/presets
"""

import csv
import sys
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    import numpy as np
except ImportError:
    print('Install matplotlib first:  pip3 install matplotlib')
    sys.exit(1)

# Fixed presentation order used across every results chart in the diploma.
LIBS = ['provider', 'riverpod', 'getx', 'watch_it']
LABELS = {'riverpod': 'Riverpod', 'getx': 'GetX',
          'provider': 'Provider', 'watch_it': 'Watch_It'}
COLORS = {'riverpod': '#0175C2', 'getx': '#F76C5E',
          'provider': '#7AB317', 'watch_it': '#FFB400'}
MARKERS = {'riverpod': 'o', 'getx': 's', 'provider': '^', 'watch_it': 'D'}
LINESTYLES = {'riverpod': '-', 'getx': '--', 'provider': '-.', 'watch_it': ':'}
PRESETS = ['none', 'light', 'medium', 'heavy']
DSIZE = {'none': 0, 'light': 100, 'medium': 1000, 'heavy': 5000}


def load_agg(results_dir):
    data = {}  # (preset, lib, event) -> row dict
    for p in PRESETS:
        f = Path(results_dir) / p / 'aggregated.csv'
        if not f.exists():
            continue
        with open(f) as fh:
            for r in csv.DictReader(fh):
                data[(p, r['library'], r['event'])] = r
    return data


def preset_chart(data, event, mean_col, std_col, ylabel, title, out):
    # only presets that actually have this event
    xs = [p for p in PRESETS if any((p, l, event) in data for l in LIBS)]
    if not xs:
        print(f'  (skip {out.name} — no data for {event})')
        return
    xlabels = [f'{p}\n(n={DSIZE[p]})' for p in xs]

    fig, ax = plt.subplots(figsize=(8, 5))
    x = list(range(len(xs)))
    # All libraries share the same x per preset (same vertical line). Overlapping
    # libraries stay distinguishable via distinct markers + DECREASING marker
    # sizes (concentric when they coincide) + distinct line styles.
    for i, lib in enumerate(LIBS):
        ys, es = [], []
        for p in xs:
            r = data.get((p, lib, event))
            ys.append(float(r[mean_col]) if r else np.nan)
            es.append(float(r[std_col]) if r else 0.0)
        ax.errorbar(x, ys, yerr=es, marker=MARKERS[lib],
                    linestyle=LINESTYLES[lib], markersize=13 - 2 * i,
                    capsize=3, linewidth=2, alpha=0.8,
                    label=LABELS[lib], color=COLORS[lib])
    ax.set_xticks(x)
    ax.set_xticklabels(xlabels)
    ax.set_xlabel('Obremenitveni scenarij (velikost nabora podatkov)')
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.legend()
    ax.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()
    print(f'  → {out}')


if __name__ == '__main__':
    results = sys.argv[1] if len(sys.argv) > 1 else 'results/advanced'
    out_dir = Path(sys.argv[2] if len(sys.argv) > 2 else 'figures/advanced/presets')
    out_dir.mkdir(parents=True, exist_ok=True)

    data = load_agg(results)
    if not data:
        print(f'No aggregated.csv found under {results}/<preset>/')
        sys.exit(1)

    print(f'Cross-preset charts from {results} ...')
    # rebuilds — architectural properties vs dataset size
    preset_chart(data, 'edit_user', 'rebuild_count_mean', 'rebuild_count_stddev',
                 'Widget rebuilds', 'edit_user rebuilds vs dataset size',
                 out_dir / 'rebuilds_edit_by_preset.png')
    preset_chart(data, 'load_page_2', 'rebuild_count_mean', 'rebuild_count_stddev',
                 'Widget rebuilds', 'load_page_2 rebuilds vs dataset size',
                 out_dir / 'rebuilds_load2_by_preset.png')
    # memory / duration scaling
    preset_chart(data, 'load_page_1', 'rss_delta_kb_mean', 'rss_delta_kb_stddev',
                 'Sprememba RSS (KB)', 'RSS pri load_page_1 glede na velikost nabora',
                 out_dir / 'memory_load1_by_preset.png')
    preset_chart(data, 'load_page_1', 'duration_ms_mean', 'duration_ms_stddev',
                 'Duration (ms)', 'load_page_1 duration vs dataset size',
                 out_dir / 'duration_load1_by_preset.png')
    preset_chart(data, 'edit_user', 'duration_ms_mean', 'duration_ms_stddev',
                 'Duration (ms)', 'edit_user duration vs dataset size',
                 out_dir / 'duration_edit_by_preset.png')
    # pagination cost & jank scaling (viewport-bound + heavy jank)
    preset_chart(data, 'load_page_2', 'duration_ms_mean', 'duration_ms_stddev',
                 'Duration (ms)', 'load_page_2 duration vs dataset size',
                 out_dir / 'duration_load2_by_preset.png')
    preset_chart(data, 'load_page_2', 'worst_frame_ms_mean', 'worst_frame_ms_stddev',
                 'Worst frame (ms)', 'load_page_2 worst frame vs dataset size',
                 out_dir / 'worstframe_load2_by_preset.png')
    preset_chart(data, 'load_page_1', 'worst_frame_ms_mean', 'worst_frame_ms_stddev',
                 'Worst frame (ms)', 'load_page_1 worst frame vs dataset size',
                 out_dir / 'worstframe_load1_by_preset.png')
    print('Done.')
