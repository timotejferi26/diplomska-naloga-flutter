#!/usr/bin/env python3
"""Aggregate multiple benchmark CSV runs into mean/stddev tables.

Usage:
    python3 scripts/aggregate_results.py \
        results/advanced/light results/new-runs/advanced/light

Outputs:
    - aggregated.csv  (one row per library × event)
    - comparison.md   (markdown comparison tables)
"""

import csv
import sys
import statistics
from pathlib import Path
from collections import defaultdict

LIBRARIES = ['provider', 'riverpod', 'getx', 'watch_it']
EVENTS = [
    'load_page_1', 'load_page_2', 'load_page_3', 'load_page_4', 'load_page_5',
    'add_user', 'edit_user', 'delete_user',
    'search_query', 'search_clear',
]


def load_runs(csv_paths):
    """Group rows by (library, event); collect lists of each metric."""
    grouped = defaultdict(lambda: defaultdict(list))
    for path in csv_paths:
        with open(path) as f:
            for row in csv.DictReader(f):
                lib = row['library']
                event = row['event']
                grouped[(lib, event)]['duration_ms'].append(int(row['duration_ms']))
                rss_delta = row.get('rss_delta_kb', row.get('heap_delta_kb'))
                if rss_delta is None:
                    raise KeyError(
                        f'{path}: expected rss_delta_kb column'
                    )
                grouped[(lib, event)]['rss_delta_kb'].append(int(rss_delta))
                grouped[(lib, event)]['rebuild_count'].append(int(row['rebuild_count']))
                grouped[(lib, event)]['worst_frame_ms'].append(float(row['worst_frame_ms']))
    return grouped


def stats(values):
    """Return (mean, stddev, n)."""
    if not values:
        return (None, None, 0)
    n = len(values)
    mean = statistics.mean(values)
    stddev = statistics.stdev(values) if n > 1 else 0.0
    return (mean, stddev, n)


def write_aggregated(grouped, out_path):
    with open(out_path, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow([
            'library', 'event', 'n',
            'duration_ms_mean', 'duration_ms_stddev',
            'rss_delta_kb_mean', 'rss_delta_kb_stddev',
            'rebuild_count_mean', 'rebuild_count_stddev',
            'worst_frame_ms_mean', 'worst_frame_ms_stddev',
        ])
        for lib in LIBRARIES:
            for event in EVENTS:
                metrics = grouped.get((lib, event), {})
                d_mean, d_std, n = stats(metrics.get('duration_ms', []))
                h_mean, h_std, _ = stats(metrics.get('rss_delta_kb', []))
                r_mean, r_std, _ = stats(metrics.get('rebuild_count', []))
                f_mean, f_std, _ = stats(metrics.get('worst_frame_ms', []))
                if n == 0:
                    continue
                w.writerow([
                    lib, event, n,
                    f'{d_mean:.1f}', f'{d_std:.1f}',
                    f'{h_mean:.0f}', f'{h_std:.0f}',
                    f'{r_mean:.1f}', f'{r_std:.1f}',
                    f'{f_mean:.2f}', f'{f_std:.2f}',
                ])


def write_markdown(grouped, out_path, n_runs):
    lines = ['# Benchmark Results — Aggregated\n']

    for metric_key, metric_label, fmt in [
        ('duration_ms', 'Duration (ms)', '{:.1f} ± {:.1f}'),
        ('rss_delta_kb', 'RSS Δ (KB)', '{:.0f} ± {:.0f}'),
        ('rebuild_count', 'Rebuilds', '{:.1f} ± {:.1f}'),
        ('worst_frame_ms', 'Worst frame (ms)', '{:.2f} ± {:.2f}'),
    ]:
        lines.append(f'\n## {metric_label}\n')
        lines.append('| Event | ' + ' | '.join(LIBRARIES) + ' |')
        lines.append('|---|' + '---|' * len(LIBRARIES))
        for event in EVENTS:
            cells = []
            for lib in LIBRARIES:
                values = grouped.get((lib, event), {}).get(metric_key, [])
                if not values:
                    cells.append('—')
                else:
                    mean, std, _ = stats(values)
                    cells.append(fmt.format(mean, std))
            lines.append(f'| {event} | ' + ' | '.join(cells) + ' |')

    lines.append(
        f'\n_Based on {n_runs} iteration(s) per preset. Values shown as '
        f'mean ± stddev. Sample size n per (library, event) cell is in '
        f'`aggregated.csv`._\n'
    )

    with open(out_path, 'w') as f:
        f.write('\n'.join(lines))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python3 scripts/aggregate_results.py '
              '<input-run-dir> <output-dir>')
        sys.exit(1)

    input_dir = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    if not input_dir.is_dir():
        print(f'Input directory does not exist: {input_dir}')
        sys.exit(1)
    if input_dir.resolve() == out_dir.resolve():
        print('Refusing to overwrite the input results directory.')
        sys.exit(1)

    paths = sorted(input_dir.glob('run_*.csv'))

    paths = [p for p in paths if p.exists()]
    if not paths:
        print(f'No run_*.csv files found in {input_dir}.')
        sys.exit(1)

    grouped = load_runs(paths)
    out_dir.mkdir(parents=True, exist_ok=True)

    csv_out = out_dir / 'aggregated.csv'
    md_out = out_dir / 'comparison.md'
    write_aggregated(grouped, csv_out)
    write_markdown(grouped, md_out, n_runs=len(paths))

    print(f'✓ Aggregated {len(paths)} run(s)')
    print(f'  → {csv_out}')
    print(f'  → {md_out}')
