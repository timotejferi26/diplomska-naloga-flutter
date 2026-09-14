#!/usr/bin/env python3
"""Stacked-bar chart of the per-widget-type rebuild breakdown,
default use vs advanced implementation, for the discriminating events.

Reads breakdown_summary.csv (library,event,list_page,card,total) from the two
results dirs and draws, per event, two stacked bars per library — default
use and advanced implementation — each split into card (bottom) + list page
(top).

Usage:
    python3 scripts/generate_breakdown_chart.py \
        results/default results/advanced figures/breakdown_by_type.png
"""
import csv
import sys
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    import numpy as np
    from matplotlib.patches import Patch
except ImportError:
    print('Install matplotlib first:  pip3 install matplotlib')
    sys.exit(1)

# Fixed presentation order used across every results chart in the diploma.
LIBS = ['provider', 'riverpod', 'getx', 'watch_it']
LABELS = {'riverpod': 'Riverpod', 'getx': 'GetX',
          'provider': 'Provider', 'watch_it': 'Watch_It'}
EVENTS = [('edit_user', 'Urejanje uporabnika (edit_user)'),
          ('load_page_2', 'Nalaganje 2. strani (load_page_2)')]
CARD_C = '#4C72B0'   # cards
PAGE_C = '#DD8452'   # list page
PRESET = 'light'


def load(results_dir):
    data = {}
    f = Path(results_dir) / PRESET / 'breakdown_summary.csv'
    with open(f) as fh:
        for r in csv.DictReader(fh):
            data[(r['library'], r['event'])] = (
                int(r['list_page']), int(r['card']), int(r['total']))
    return data


def main():
    default_results = sys.argv[1] if len(sys.argv) > 1 else 'results/default'
    advanced_results = sys.argv[2] if len(sys.argv) > 2 else 'results/advanced'
    out = Path(sys.argv[3] if len(sys.argv) > 3
               else 'figures/breakdown_by_type.png')
    out.parent.mkdir(parents=True, exist_ok=True)
    default_data = load(default_results)
    advanced_data = load(advanced_results)

    fig, axes = plt.subplots(1, len(EVENTS), figsize=(12, 5.8))
    versions = [('Privzeta uporaba', default_data, 0.42),
                ('Napredna implementacija', advanced_data, 1.0)]
    w = 0.34
    for ax, (event, title) in zip(axes, EVENTS):
        x = np.arange(len(LIBS))
        ymax = max(max(default_data[(l, event)][2], advanced_data[(l, event)][2])
                   for l in LIBS) * 1.2
        for off, (version_label, data, alpha) in zip(
                (-w / 2 - 0.02, w / 2 + 0.02), versions):
            cards = [data[(l, event)][1] for l in LIBS]
            pages = [data[(l, event)][0] for l in LIBS]
            totals = [data[(l, event)][2] for l in LIBS]
            ax.bar(x + off, cards, w, color=CARD_C, alpha=alpha,
                   edgecolor='white', linewidth=0.7)
            ax.bar(x + off, pages, w, bottom=cards, color=PAGE_C,
                   alpha=alpha, edgecolor='white', linewidth=0.7)
            for xi, total in zip(x + off, totals):
                ax.text(xi, total + ymax * 0.02, str(total), ha='center',
                        va='bottom', fontsize=9, fontweight='bold')
        ax.set_xticks(x)
        ax.set_xticklabels([LABELS[l] for l in LIBS])
        ax.tick_params(axis='x', pad=5)
        ax.set_ylim(0, ymax)
        ax.grid(axis='y', alpha=0.3)
        ax.set_axisbelow(True)
        ax.set_ylabel('Ponovne gradnje (po tipu gradnika)')
        ax.set_title(title, fontsize=11.5, pad=9)

    type_legend = [
        Patch(facecolor=CARD_C, label='Kartica'),
        Patch(facecolor=PAGE_C, label='Seznamska stran'),
    ]
    version_legend = [
        Patch(facecolor='#666', alpha=0.42, label='Privzeta uporaba'),
        Patch(facecolor='#666', alpha=1.0,
              label='Napredna implementacija'),
    ]
    fig.legend(handles=type_legend, title='Tip gradnika', loc='upper center',
               ncol=2, frameon=False, bbox_to_anchor=(0.31, 1.01))
    fig.legend(handles=version_legend, title='Način uporabe',
               loc='upper center', ncol=2, frameon=False,
               bbox_to_anchor=(0.72, 1.01))
    fig.text(0.5, 0.012,
             'Obremenitveni scenarij »light«; obe meritvi uporabljata '
             'deterministični jumpTo.',
             ha='center', fontsize=8.5, color='#555')
    plt.tight_layout(rect=(0, 0.055, 1, 0.9), w_pad=2.0)
    plt.savefig(out, dpi=150)
    plt.close()
    print(f'→ {out}')


if __name__ == '__main__':
    main()
