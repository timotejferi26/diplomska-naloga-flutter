# Primerjava knjižnic za upravljanje stanja in vrivanje odvisnosti v Flutterju

Javni repozitorij spremljevalnega gradiva diplomskega dela. Vsebuje demonstracijsko aplikacijo za primerjavo knjižnic **Provider, Riverpod, GetX in Watch_It**, enotske teste, merilne preizkuse, končne rezultate ter skripte za njihovo obdelavo in izdelavo grafov.

Aplikacija omogoča nalaganje uporabnikov po straneh, dodajanje, urejanje, brisanje in iskanje. Knjižnice uporabljajo skupni domenski in podatkovni sloj ter skupno merilno infrastrukturo.

## Dve ravni implementacije

| Mapa | Način uporabe |
|---|---|
| `default` | Privzeti oziroma uradno priporočeni način uporabe knjižnice, izbran za obravnavano aplikacijo. |
| `advanced` | Napredna implementacija, ki v največji meri izkorišča arhitekturne zmožnosti knjižnice za lokalizirane ponovne gradnje gradnikov. |

Obe ravni sta vključeni v en Flutterjev projekt. Vsaka knjižnica ima ločeni podmapi `default` in `advanced`, skupni sloji pa so zapisani samo enkrat. Ločeni vstopni datoteki omogočata zagon in merjenje posamezne ravni. Pri Riverpodu je knjižnična implementacija na obeh ravneh enaka, razen poti uvozov.

```text
lib/
├── core/                  Skupne odvisnosti, storitve in meritve
├── data/                  Podatkovni viri in implementacija repozitorija
├── domain/                Entitete, primeri uporabe in validacija
├── libraries/
│   ├── provider/          default/ in advanced/
│   ├── riverpod/          default/ in advanced/
│   ├── getx/              default/ in advanced/
│   └── watch_it/          default/ in advanced/
├── main.dart              Privzeti vstop v aplikacijo
├── main_default.dart      Privzeta uporaba
└── main_advanced.dart     Napredna implementacija
test/
├── default/               Enotski testi privzete uporabe
├── advanced/              Enotski testi napredne implementacije
├── domain/                Regresijska testa validacije in podatkovnega sloja
├── widget/                Urejanje kartic v vseh osmih izvedbah
└── support/               Skupni nadomestni repozitorij
integration_test/          Merilna preizkusa obeh ravni
test_driver/               Gonilnik za flutter drive
results/                  Končne meritve: default/ in advanced/
figures/                  Grafi, ponovno izdelani iz objavljenih podatkov
scripts/                  Zagon testov, meritve in obdelava podatkov
```

## Okolje in različice paketov

Enotski testi in statična analiza projekta so bili preverjeni s **Flutterjem 3.41.2 in Dartom 3.11.0**. To je okolje preverjanja projekta; samo po sebi ne določa okolja, v katerem so nastale objavljene meritve. Za aplikacijo in merilne preizkuse je vključen projekt Android. Za meritve uporabite fizično napravo z omogočenim razhroščevanjem USB.

Repozitorij vključuje `pubspec.lock` s točno določenimi neposrednimi in posrednimi odvisnostmi:

| Knjižnica | Omejitev v `pubspec.yaml` | Različica v `pubspec.lock` |
|---|---|---|
| Provider | `^6.1.5` | `6.1.5+1` |
| Riverpod (`flutter_riverpod`) | `^2.6.1` | `2.6.1` |
| GetX (`get`) | `^4.7.2` | `4.7.3` |
| Watch_It (`watch_it`) | `^2.4.2` | `2.4.2` |

Za ohranitev različic uporabite `flutter pub get` in priloženo zaklepno datoteko. Ukaz `flutter pub upgrade` lahko različice spremeni.

Priložena datoteka `.fvmrc` določa Flutter 3.41.2, ki je bil uporabljen tudi pri preverjanju projekta. Če uporabljate FVM, različico namestite z ukazom `fvm install`, spodnjim ukazom `flutter` pa lahko dodate predpono `fvm`.

## Zagon aplikacije

V korenski mapi repozitorija preverite okolje in namestite zaklenjene odvisnosti:

```bash
flutter --version
flutter doctor
flutter pub get
flutter devices
```

Zaženite izbrano raven:

```bash
# Privzeta uporaba (enakovredno: flutter run)
flutter run -t lib/main_default.dart

# Napredna implementacija
flutter run -t lib/main_advanced.dart
```

Ob več povezanih napravah ukazu dodajte `-d "ID_NAPRAVE"`, pri čemer nadomestite `ID_NAPRAVE` z dejanskim identifikatorjem. V aplikaciji izberete Provider, Riverpod, GetX ali Watch_It.

## Avtomatizirani testi

Vsaka raven vsebuje 36 enotskih testov: devet scenarijev za vsako knjižnico. Preverjajo nalaganje, dodajanje, urejanje, brisanje, iskanje, validacijo ter zamenjavo odvisnosti, asinhrono inicializacijo in izolacijo stanja po čiščenju. Uporabljajo skupni nadomestni repozitorij; ne izvajajo uporabniškega vmesnika ali dejanskih podatkovnih virov.

```bash
flutter test test/default/state_management_unit_test.dart
flutter test test/advanced/state_management_unit_test.dart
```

Oba sklopa, skupna regresijska testa in osem testov uporabniškega vmesnika lahko zaženete z `flutter test` ali s skripto `./scripts/verify.sh`. Uspešnih je vseh 82 testov: 72 testov knjižničnih implementacij, dva testa produkcijske validacije ter podatkovnega sloja in osem testov, ki preverijo prikaz urejenega uporabnika na kartici v vsaki kombinaciji knjižnice ter ravni implementacije. Test napredne implementacije Watch_It preveri tudi pravilno zamenjavo naročnine po ponovnem nalaganju podatkov. Merilna preizkusa obeh ravni sta bila funkcionalno preverjena v profilnem načinu s scenarijem `light` na napravi Samsung SM-G985F z Androidom 13; ta preveritvena zagona ne nadomeščata celotnega objavljenega nabora meritev.

## Merilni preizkusi

Merijo trajanje operacij, spremembo rezidenčnega pomnilniškega odtisa (RSS), število ponovnih gradenj gradnikov in trajanje najslabšega okvirja.

| Scenarij | Začetno število uporabnikov | Velikost strani (`pageSize`) |
|---|---:|---:|
| `none` | 0 | 20 |
| `light` | 100 | 20 |
| `medium` | 1000 | 20 |
| `heavy` | 5000 | 50 |

En profilni zagon izvedete tako:

```bash
DEVICE="ID_NAPRAVE" ./scripts/run_benchmark.sh default light
DEVICE="ID_NAPRAVE" ./scripts/run_benchmark.sh advanced light
```

Vsak ukaz izvede en preizkus vseh štirih knjižnic. Za pet ponovitev ukaz ponovite petkrat in shranite izvoz vsake ponovitve. Preizkusa ohranjata izvorni vrstni red izvajanja Riverpod, GetX, Provider, Watch_It; prikaz v menijih in grafih uporablja vrstni red Provider, Riverpod, GetX, Watch_It.

Izvoz ustvari datoteki `benchmark_<časovni_žig>.csv` in `.json`, praviloma v `/sdcard/Download`. Dejanska izvozna mapa je izpisana ob zaključku preizkusa. Za nadaljnjo obdelavo shranite posamezne profilne izvoze kot `run_1.csv` do `run_5.csv` v novo mapo, na primer `results/new-runs/advanced/light/`.

Razčlenitev po tipih gradnikov zahteva ločen zagon v načinu `debug`. Primer za napredno implementacijo:

```bash
mkdir -p runs/advanced
set -o pipefail
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/advanced_benchmark_test.dart \
  --debug \
  --dart-define=PRESET=light \
  -d "ID_NAPRAVE" 2>&1 | tee runs/advanced/breakdown_light.log

python3 scripts/parse_breakdown.py \
  runs/advanced/breakdown_light.log \
  results/new-runs/advanced/light
```

Pri privzeti uporabi zamenjajte `advanced` z `default`. Razčlenitev po tipih izhaja iz dnevnika zagona; sam izvoz CSV vsebuje skupno število ponovnih gradenj. Časovnih in pomnilniških meritev načina `debug` ne združujte s profilnimi ponovitvami.

## Objavljeni podatki in grafi

Končni podatki so v [results/default](results/default) in [results/advanced](results/advanced). Vsaka raven vsebuje štiri scenarije s petimi profilnimi ponovitvami ter izračunanimi povprečji in vzorčnimi standardnimi odkloni. Ločena razčlenitev po tipih gradnikov je vključena za `light` in `heavy`. Podrobnosti o datotekah so v [opisu rezultatov](results/README.md).

Stolpec `rss_delta_kb` predstavlja **spremembo RSS**, ne celotne porabe pomnilnika ali velikosti Dartove kopice. Objavljene datoteke ohranite kot referenčne podatke diplomskega dela. Nove meritve shranjujte ločeno; njihove vrednosti so lahko odvisne od naprave in izvajalnega okolja.

Ponovni izračun povprečij in vzorčnega standardnega odklona (`n − 1`) iz objavljenih ponovitev:

```bash
python3 scripts/aggregate_results.py \
  results/advanced/light results/new-runs/recalculated/advanced/light
```

Za grafe potrebujete Python, NumPy in Matplotlib. Ustvarite ločeno okolje:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install numpy matplotlib
```

Primer ponovne izdelave grafov v ločeno izhodno mapo:

```bash
mkdir -p results/new-runs/figures
python scripts/generate_charts.py \
  results/advanced/light results/new-runs/figures/advanced
python scripts/generate_preset_charts.py \
  results/advanced results/new-runs/figures/advanced/presets
python scripts/generate_breakdown_chart.py \
  results/default results/advanced results/new-runs/figures/breakdown_by_type.png
```

Za grafe privzete uporabe pri prvih dveh ukazih zamenjajte `advanced` z `default`. Primerjalni graf razčlenitve uporablja podatke obeh ravni. Različice Pythonovih paketov trenutno niso zaklenjene, zato enakih slik na ravni posameznih slikovnih pik ni mogoče zagotoviti.
