# Končni rezultati meritev

Mapa vsebuje podatke, uporabljene v diplomskem delu:

- `default`: privzeta oziroma uradno priporočena uporaba knjižnic;
- `advanced`: napredna implementacija;
- `none`, `light`, `medium` in `heavy`: 0, 100, 1000 in 5000 začetnih
  uporabnikov.

V vsaki mapi scenarija so:

| Datoteka | Vsebina |
|---|---|
| `run_1.csv`–`run_5.csv` | surove meritve petih profilnih ponovitev |
| `aggregated.csv` | povprečje in vzorčni standardni odklon (`n - 1`) |
| `comparison.md` | berljiv, iz podatkov izpeljan povzetek |
| `breakdown.csv`/`.json` | izvoz ločenega zagona v načinu `debug` |
| `breakdown_by_type.csv` | ponovne gradnje po tipu gradnika |
| `breakdown_summary.csv` | razčlenitev na seznamsko stran in kartice |

Razčlenitev po tipih je vključena za scenarija `light` in `heavy`. Profilne
meritve so bile za obe implementaciji izvedene z enakim determinističnim
premikom `jumpTo`.

Stolpec `rss_delta_kb` pomeni spremembo rezidenčnega pomnilniškega odtisa (RSS),
ne velikosti Dartove kopice. Časovni žigi so del izvornega merilnega izvoza.

Objavljene datoteke so končna podatkovna priloga. Skripte naj nove rezultate
zapišejo v `results/new-runs`, da se ti podatki ne prepišejo.
