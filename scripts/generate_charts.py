#!/usr/bin/env python3
"""Generate comparison charts from aggregated benchmark results.

Usage:
    python3 scripts/generate_charts.py results/advanced/light figures/advanced
"""

import csv
import sys
from pathlib import Path
from collections import defaultdict

try:
    import matplotlib.pyplot as plt
    import numpy as np
except ImportError:
    print('Install matplotlib first:  pip3 install matplotlib')
    sys.exit(1)

# Fixed presentation order used across every results chart in the diploma.
LIBRARIES = ['provider', 'riverpod', 'getx', 'watch_it']
LIB_LABELS = {'riverpod': 'Riverpod', 'getx': 'GetX',
              'provider': 'Provider', 'watch_it': 'Watch_It'}
LIB_COLORS = {'riverpod': '#0175C2', 'getx': '#F76C5E',
              'provider': '#7AB317', 'watch_it': '#FFB400'}
EVENTS = ['load_page_1', 'load_page_2', 'load_page_3',
          'add_user', 'edit_user', 'delete_user',
          'search_query', 'search_clear']
EVENT_LABELS = {
    'load_page_1': 'Nalaganje 1. strani\n(load_page_1)',
    'load_page_2': 'Nalaganje 2. strani\n(load_page_2)',
    'load_page_3': 'Nalaganje 3. strani\n(load_page_3)',
    'add_user': 'Dodajanje uporabnika\n(add_user)',
    'edit_user': 'Urejanje uporabnika\n(edit_user)',
    'delete_user': 'Brisanje uporabnika\n(delete_user)',
    'search_query': 'Iskanje\n(search_query)',
    'search_clear': 'Čiščenje iskanja\n(search_clear)',
}


def load_runs(csv_paths):
    grouped = defaultdict(lambda: defaultdict(list))
    for path in csv_paths:
        with open(path) as f:
            for row in csv.DictReader(f):
                lib = row['library']
                event = row['event']
                grouped[(lib, event)]['duration_ms'].append(int(row['duration_ms']))
                # Final benchmark exports name this RSS metric ``rss_delta_kb``;
                # older result sets used ``heap_delta_kb``. Support both so the
                # published charts remain reproducible from either dataset.
                memory_delta = row.get('rss_delta_kb', row.get('heap_delta_kb'))
                if memory_delta is None:
                    raise KeyError('Expected rss_delta_kb or heap_delta_kb column')
                grouped[(lib, event)]['rss_delta_kb'].append(int(memory_delta))
                grouped[(lib, event)]['rebuild_count'].append(int(row['rebuild_count']))
                grouped[(lib, event)]['worst_frame_ms'].append(float(row['worst_frame_ms']))
    return grouped


def chart(grouped, metric_key, ylabel, title, out_path, log_scale=False):
    fig, ax = plt.subplots(figsize=(11, 5.5))
    x = np.arange(len(EVENTS))
    width = 0.2

    for i, lib in enumerate(LIBRARIES):
        means = []
        stds = []
        for event in EVENTS:
            values = grouped.get((lib, event), {}).get(metric_key, [])
            if values:
                means.append(np.mean(values))
                # Use the sample standard deviation, matching aggregated.csv
                # and the mean ± SD values reported in the thesis tables.
                stds.append(np.std(values, ddof=1) if len(values) > 1 else 0)
            else:
                means.append(0)
                stds.append(0)
        offset = (i - 1.5) * width
        ax.bar(x + offset, means, width, yerr=stds, capsize=3,
               label=LIB_LABELS[lib], color=LIB_COLORS[lib],
               error_kw={'elinewidth': 1, 'alpha': 0.7})

    ax.set_xlabel('Operacija')
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.set_xticks(x)
    ax.set_xticklabels([EVENT_LABELS[e] for e in EVENTS],
                       rotation=30, ha='right', fontsize=8)
    ax.legend()
    ax.grid(axis='y', alpha=0.3)
    if log_scale:
        ax.set_yscale('log')

    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    plt.close()
    print(f'  → {out_path}')


if __name__ == '__main__':
    # Optional args: <input-run-dir> <output-fig-dir> <filename-suffix>
    #   python3 scripts/generate_charts.py results/advanced/light figures/advanced
    in_dir = Path(sys.argv[1]) if len(sys.argv) > 1 \
        else Path('results/advanced/light')
    out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('figures/advanced')
    sfx = sys.argv[3] if len(sys.argv) > 3 else ''

    csv_paths = sorted(in_dir.glob('run_*.csv'))
    if not csv_paths:
        print(f'No CSVs found in {in_dir}/')
        sys.exit(1)

    out_dir.mkdir(parents=True, exist_ok=True)

    grouped = load_runs(csv_paths)

    print(f'Generating charts from {len(csv_paths)} runs...')
    chart(grouped, 'duration_ms', 'Trajanje (ms)',
          'Trajanje operacij po knjižnicah',
          out_dir / f'duration{sfx}.png')
    chart(grouped, 'rebuild_count', 'Ponovne gradnje gradnikov',
          'Število ponovnih gradenj gradnikov po knjižnicah',
          out_dir / f'rebuilds{sfx}.png')
    chart(grouped, 'rss_delta_kb', 'Sprememba RSS (KB)',
          'Sprememba porabe pomnilnika po knjižnicah',
          out_dir / f'memory{sfx}.png')
    chart(grouped, 'worst_frame_ms', 'Najslabši okvir (ms)',
          'Trajanje najslabšega okvirja po knjižnicah',
          out_dir / f'worst_frame{sfx}.png')
    print('Done.')
