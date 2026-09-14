# Benchmark Results — Aggregated


## Duration (ms)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 17.4 ± 2.7 | 46.4 ± 15.6 | 21.8 ± 5.1 | 22.2 ± 1.3 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 21.3 ± 2.7 | 24.4 ± 3.8 | 20.1 ± 3.6 | 22.1 ± 3.7 |
| edit_user | 16.0 ± 4.0 | 17.4 ± 4.4 | 11.6 ± 0.9 | 13.0 ± 4.6 |
| delete_user | 26.6 ± 3.6 | 27.2 ± 1.6 | 27.0 ± 0.7 | 28.4 ± 1.9 |
| search_query | 18.4 ± 3.8 | 14.8 ± 4.1 | 15.0 ± 4.7 | 19.8 ± 5.1 |
| search_clear | 25.4 ± 3.8 | 26.8 ± 7.4 | 21.6 ± 1.1 | 24.0 ± 1.0 |

## RSS Δ (KB)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 3296 ± 30 | 10538 ± 786 | -2818 ± 8241 | 2393 ± 1111 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 2234 ± 1340 | 1389 ± 1711 | 1352 ± 1531 | 1224 ± 1505 |
| edit_user | -177 ± 1263 | -118 ± 972 | -1142 ± 920 | -706 ± 1152 |
| delete_user | 803 ± 1092 | -86 ± 65 | 855 ± 1100 | 1087 ± 1057 |
| search_query | 155 ± 841 | 508 ± 69 | 361 ± 60 | 965 ± 952 |
| search_clear | 3426 ± 1786 | 2944 ± 1098 | 3446 ± 869 | 4209 ± 138 |

## Rebuilds

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 1.0 ± 0.0 | 1.0 ± 0.0 | 0.0 ± 0.0 | 1.0 ± 0.0 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 4.0 ± 1.4 | 4.0 ± 1.4 | 3.0 ± 1.4 | 4.0 ± 1.4 |
| edit_user | 2.0 ± 0.0 | 2.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| delete_user | 5.0 ± 0.0 | 5.0 ± 0.0 | 4.0 ± 0.0 | 5.0 ± 0.0 |
| search_query | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 2.0 ± 0.0 |
| search_clear | 6.0 ± 0.0 | 6.0 ± 0.0 | 5.0 ± 0.0 | 6.0 ± 0.0 |

## Worst frame (ms)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 17.12 ± 3.30 | 32.78 ± 8.67 | 16.42 ± 2.18 | 17.52 ± 1.47 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 16.54 ± 2.68 | 20.26 ± 2.86 | 15.54 ± 2.68 | 17.10 ± 2.86 |
| edit_user | 14.80 ± 2.61 | 14.45 ± 2.17 | 15.68 ± 6.67 | 12.25 ± 1.13 |
| delete_user | 16.89 ± 1.31 | 17.88 ± 1.61 | 15.89 ± 0.56 | 16.76 ± 1.17 |
| search_query | 11.99 ± 1.95 | 11.40 ± 2.00 | 12.85 ± 1.35 | 12.93 ± 2.86 |
| search_clear | 19.72 ± 1.98 | 22.10 ± 7.09 | 17.88 ± 1.64 | 19.18 ± 0.92 |

_Based on 5 iteration(s) per preset. Values shown as mean ± stddev. Sample size n per (library, event) cell is in `aggregated.csv`._
