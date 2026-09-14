# Benchmark Results — Aggregated


## Duration (ms)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 23.8 ± 3.2 | 47.6 ± 14.4 | 24.6 ± 2.1 | 29.0 ± 5.1 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 31.7 ± 7.4 | 33.4 ± 7.4 | 28.2 ± 7.4 | 29.7 ± 7.1 |
| edit_user | 23.6 ± 4.0 | 22.6 ± 7.4 | 21.0 ± 4.8 | 27.4 ± 7.1 |
| delete_user | 41.0 ± 10.2 | 35.8 ± 7.4 | 32.4 ± 6.2 | 32.4 ± 12.7 |
| search_query | 28.2 ± 5.2 | 22.0 ± 5.2 | 23.0 ± 6.8 | 19.8 ± 7.9 |
| search_clear | 38.8 ± 12.0 | 44.2 ± 7.5 | 45.6 ± 4.4 | 43.8 ± 13.2 |

## RSS Δ (KB)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 2510 ± 1155 | 10549 ± 1065 | 2663 ± 978 | 3708 ± 1935 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 2964 ± 1361 | 2746 ± 1505 | 2652 ± 1431 | 3036 ± 1349 |
| edit_user | 2680 ± 814 | 215 ± 852 | 2572 ± 1022 | 2591 ± 827 |
| delete_user | 282 ± 1026 | 230 ± 1060 | -138 ± 1161 | 263 ± 953 |
| search_query | -125 ± 1240 | -1053 ± 853 | -422 ± 1776 | -615 ± 1123 |
| search_clear | 3353 ± 1098 | 1294 ± 1831 | 2692 ± 1157 | 2902 ± 1901 |

## Rebuilds

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 1.0 ± 0.0 | 1.0 ± 0.0 | 0.0 ± 0.0 | 1.0 ± 0.0 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 4.0 ± 1.4 | 4.0 ± 1.4 | 3.0 ± 1.4 | 4.0 ± 1.4 |
| edit_user | 6.0 ± 0.0 | 2.0 ± 0.0 | 5.0 ± 0.0 | 6.0 ± 0.0 |
| delete_user | 5.0 ± 0.0 | 5.0 ± 0.0 | 4.0 ± 0.0 | 5.0 ± 0.0 |
| search_query | 2.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 2.0 ± 0.0 |
| search_clear | 6.0 ± 0.0 | 6.0 ± 0.0 | 5.0 ± 0.0 | 6.0 ± 0.0 |

## Worst frame (ms)

| Event | provider | riverpod | getx | watch_it |
|---|---|---|---|---|
| load_page_1 | 27.69 ± 10.82 | 32.64 ± 7.23 | 25.05 ± 4.99 | 26.77 ± 5.88 |
| load_page_2 | — | — | — | — |
| load_page_3 | — | — | — | — |
| load_page_4 | — | — | — | — |
| load_page_5 | — | — | — | — |
| add_user | 25.34 ± 6.25 | 28.99 ± 6.74 | 22.51 ± 5.93 | 24.18 ± 5.88 |
| edit_user | 20.40 ± 3.47 | 21.12 ± 5.84 | 19.22 ± 3.18 | 22.19 ± 5.88 |
| delete_user | 29.72 ± 7.98 | 26.89 ± 7.17 | 25.33 ± 5.05 | 23.69 ± 9.67 |
| search_query | 17.98 ± 1.86 | 13.80 ± 0.51 | 14.04 ± 2.49 | 13.72 ± 6.07 |
| search_clear | 31.31 ± 8.76 | 34.03 ± 8.10 | 36.35 ± 1.81 | 33.72 ± 12.21 |

_Based on 5 iteration(s) per preset. Values shown as mean ± stddev. Sample size n per (library, event) cell is in `aggregated.csv`._
