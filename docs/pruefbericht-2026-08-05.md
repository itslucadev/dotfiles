# Prüfbericht, 5. August 2026

Fünf unabhängige Prüfer sind über das Repository gelaufen, jeder mit dem Auftrag, Fehler nachzuweisen statt zu bestätigen.
Alle fünf haben geliefert.

Zusammen haben sie rund vierzig Punkte gemeldet.
Dieses Dokument listet jeden Befund, der wirklich Auswirkungen gehabt hätte, was daran falsch war und was daraus geworden ist.

Stand: Commit `e83e38a`.

## Die fünf Prüfbereiche

| Prüfer | Bereich | Belegte Funde |
| --- | --- | --- |
| Bootstrap | `bootstrap.sh` und die sieben Skripte | 10 |
| Inventar | `Brewfile`, `Brewfile.mas`, `mise.toml` | 5 |
| Editoren | Extension-Inventare und Editor-Einstellungen | 7 |
| Agenten | Skills, Claude-Einstellungen, Regeln, Herdr | 7 |
| Dokumentation | README, AGENTS.md, Setup-Guide, .gitignore | 15 |

## Die fünf schwersten Befunde

### 1. Der Einrichtungsvorgang wäre abgebrochen

**Wo:** `scripts/install-agent-skills.sh`, `home/.config/skills/default-skills.txt`

Jede Skill-Quelle war auf eine exakte Commit-Kennnummer festgenagelt, damit der neue Mac einen geprüften Stand bekommt statt irgendeines aktuellen.

Das Werkzeug, das diese Skills holt, kann mit so einer Kennnummer aber gar nicht umgehen.
Es klont eine Quelle mit `git clone --branch`, und dieser Schalter akzeptiert ausschließlich Zweig- oder Versionsnamen.
Empirisch belegt:

```
$ git clone --depth 1 --branch 2ab958093e... https://github.com/mattpocock/skills.git
fatal: Remote branch 2ab958093e... not found in upstream origin
```

Es gibt genau einen Weg im Werkzeug, der mit Kennnummern umgehen kann, und der ist auf drei Projekt-Eigentümer beschränkt:

```js
const BLOB_ALLOWED_OWNERS = ["vercel", "vercel-labs", "heygen-com"];
```

Das erklärt, warum es früher teilweise zu funktionieren schien: Die alten Quellen von `vercel-labs` fielen in diese Ausnahme, alle anderen wären genauso gescheitert.
Version 1.5.21 ist die aktuelle, es gibt keine neuere, die das behebt.

**Auswirkung:** Das Skript wäre an der ersten Quelle gescheitert und hätte den gesamten Einrichtungsvorgang eine Stufe vor dem Doctor mitgerissen, auf jedem neuen Mac.
Der Probelauf hätte es nicht gezeigt, weil er nur ausgibt, was passieren würde.

**Erledigt:** Das Festnageln ist entfallen. Die Liste enthält jetzt schlichte Projekt-Adressen, und das Werkzeug bekommt sie direkt.

### 2. Ghostty wäre ohne jede Einstellung gestartet

**Wo:** `home/.config/ghostty/`

Ghostty liest ausschließlich eine Datei namens `config`.
Im Repository hieß sie `config.ghostty`, und mise verlinkt das ganze Verzeichnis.

**Auswirkung:** Kein Farbschema, keine Schrift, keine Transparenz, kein Weichzeichner.
Der heimtückische Teil: Das wäre nie als Fehler aufgefallen, sondern nur als "sieht irgendwie anders aus".

**Erledigt:** Datei umbenannt. Der Grund steht jetzt im README, damit sie niemand zurückbenennt.

### 3. Cursor wäre bei jedem Lauf gescheitert, ohne es zu melden

**Wo:** `home/.config/editors/extensions.txt`, `scripts/install-editor-extensions.sh`

Drei Fehler, die sich gegenseitig verdeckt haben.

Die Erweiterung `sukarth.vscode-modernized` stand im gemeinsamen Inventar, liegt aber nur im Microsoft-Laden.
Weder Open VSX noch Cursors eigener Katalog kennen sie, der Namensraum `sukarth` existiert dort gar nicht.
Die anderen 21 sind in beiden Katalogen vorhanden.

Fehlte das Kommando `code`, brach die ganze Funktion ab, bevor der Cursor-Teil überhaupt erreicht wurde.

Und fehlgeschlagene Installationen gaben trotzdem Erfolg zurück, sodass der Einrichtungsvorgang die Stufe als gelungen meldete.

**Erledigt:** Die Erweiterung steht jetzt im VS-Code-Inventar, beide Editoren laufen unabhängig voneinander, und Fehlschläge beenden das Skript mit einem Fehlercode.

### 4. Der Doctor hätte auf einem perfekten Mac gemeckert

**Wo:** `scripts/doctor.sh`

Er suchte nach drei Programmen, die aus dem Inventar gestrichen wurden: Apple Developer, Notability, TestFlight.
Er kannte die vier neu aufgenommenen nicht: Linear, Obsidian, TextMate, Tower.
Er suchte nach `CleanMyMac`, obwohl das Programm `CleanMyMac_5` heißt.

Zusätzlich verlangte er jeden Skill gleichzeitig in drei Verzeichnissen.
Das Skill-Werkzeug hält aber einen zentralen Speicher und verlinkt die Agenten dort hinein, weshalb ein fehlender Link als fehlender Skill gemeldet wurde.

**Auswirkung:** Mindestens vier unvermeidbare Fehlermeldungen plus 24 falsche Skill-Meldungen auf einer korrekt eingerichteten Maschine.
`doctor.sh --strict` hätte nie erfolgreich sein können.

**Erledigt:** Programmliste am Inventar ausgerichtet, Namen gegen die echten Programm-Bezeichnungen geprüft.
Fehlender Skill im Speicher ist jetzt ein Fehler, ein fehlender Link nur eine Warnung.

### 5. Ein Fehler, der beim Reparieren entstanden ist

**Wo:** `scripts/install-agent-skills.sh`

Die Aufräumroutine, die beim Beenden die Zwischenordner löscht, endete auf einer verneinten Prüfung.
In der Shell gilt eine verneinte Prüfung als Fehlschlag, und eine solche Routine ist das Letzte, was ein Skript tut, also überschreibt ihr Ergebnis das Gesamturteil.

**Auswirkung:** Jeder Probelauf meldete einen Fehler, obwohl alles richtig lief.
`./bootstrap.sh --dry-run` brach genau dort ab.

**Erledigt:** Die Routine gibt am Ende ausdrücklich Erfolg zurück.
Der Auslöser ist inzwischen entfallen, weil das Festnageln aufgegeben wurde.

## Weitere Befunde mit Auswirkung

### Fehler, die stillschweigend verschluckt wurden

Ein Funktionsaufruf innerhalb einer `if !`-Bedingung schaltet die Fehlerabbruch-Automatik für den gesamten Funktionsrumpf ab.
Dadurch wurde eine unlesbare Inventardatei übersprungen, während der Lauf weiterhin Erfolg meldete.

Ein fehlgeschlagenes `--list-extensions` ergab eine leere Liste, was sich wie "noch nichts installiert" liest.
Der Installer hätte alles erneut installiert, der Doctor hätte jede Erweiterung als fehlend gemeldet, ohne je den wahren Grund zu zeigen.

Beides wird jetzt ausdrücklich geprüft.

### Die Schleife konnte Zeilen verlieren

Die Skill-Schleife liest ihre Liste von der Standardeingabe, und alle gestarteten Programme erben diese.
Hätte eines davon auch nur ein Byte gelesen, wären Zeilen verschwunden, ohne Fehlermeldung, nur mit einer zu niedrigen Zählung am Ende.
Alle Kindprozesse bekommen jetzt `/dev/null`.

### Der Probelauf war genau auf einer frischen Maschine unbrauchbar

Fehlte ein Werkzeug, druckten beide Installer eine Platzhalterzeile statt der echten Befehle.
Bei Herdr eine Zeile statt fünf, gefolgt von einem vorzeitigen Ende.
Die Werkzeugprüfung gilt jetzt nur noch für echte Läufe.

### Die Versionsdatei stimmt nicht mehr

`mise.lock` enthält sieben Einträge für Werkzeuge, die es in `mise.toml` nicht mehr gibt, darunter Claude Code und den Pi-Agenten, die inzwischen über Homebrew kommen.
Fünf deklarierte Werkzeuge fehlen umgekehrt ganz: `chrome-devtools-axi`, `ctx7`, `gh-axi`, `lavish-axi` und die NotebookLM-CLI.

Nur mise selbst kann diese Datei erzeugen, deshalb steht sie unangetastet.
Die Abweichung ist im README benannt, und `mise lock --bump` ist ein Punkt der Abnahmeliste.

### Zwei Laufzeiten liegen doppelt vor

Die Regel "kein Werkzeug in zwei Inventaren" war zu weit formuliert.
Homebrew zieht sich eigene Laufzeiten nach: `agent-browser` und `pi-coding-agent` bringen Node mit, `watchman` und `yt-dlp` bringen Python mit.

Das ist unvermeidbar und keine doppelte Deklaration.
Entscheidend ist die Reihenfolge in `home/.zshrc`: mise wird nach Homebrew geladen und setzt seine Verweise davor, also gewinnen die deklarierten Versionen.
Diese Reihenfolge ist jetzt als Regel festgehalten.

### Fünfzehn Widersprüche in der Dokumentation

Die auffälligsten:

- Ein Absatz erklärte Linear, Obsidian, TextMate und Tower für ausgeschlossen, dieselben vier, die dreißig Zeilen weiter oben als installiert aufgeführt sind.
- Das README behauptete, mise installiere die Codex-CLI. Sie kommt über Homebrew.
- Die Beschreibung des Ablaufs hatte die falsche Reihenfolge, listete eine Stufe auf, die es nie gab, und ließ `mise trust` aus.
- Die Ghostty-Schriftgröße stand mit 15 im README, in der Datei steht 14.
- Der Zsh-Zusatz `sunlei/zsh-ssh` fehlte in der Liste, obwohl das README diese Datei als einzige Quelle bezeichnet.
- Sechs Homebrew-Werkzeuge kamen im README überhaupt nicht vor: cocoapods, fd, jq, lazygit, ripgrep, watchman.
- AgentMail stand gleichzeitig auf der Ausschlussliste und in der Anmeldungs-Checkliste.
- `.gitignore` deckte `settings.local.json` nicht ab, obwohl zwei Dateien behaupten, die Einträge seien ein Sicherheitsnetz. Das Muster `*.local` greift dort nicht.
- Der Setup-Guide ließ noch Apple Developer, Notability und TestFlight im App Store beanspruchen und erklärte die Codex-CLI für nicht Teil des Setups.

Alle behoben.

## Was der Prüfung standgehalten hat

Nicht alles war falsch. Diese Punkte wurden gezielt angegriffen und haben gehalten:

- Alle 36 Formeln und 38 Programme im Brewfile existieren unter genau diesem Namen, keines veraltet oder abgekündigt.
- Alle zehn Drittanbieter-Pakete tragen eine eng gefasste Vertrauenserklärung, und kein offizielles Paket trägt sie unnötig.
- Alle sieben App-Store-Kennnummern gehören zur genannten Anwendung.
- Alle Einträge in `mise.toml` existieren in den jeweiligen Verzeichnissen.
- Alle 24 Skill-Namen existieren im Quellprojekt in den angegebenen Unterordnern.
- Jeder Schlüssel in `home/.claude/settings.json` existiert wirklich im Claude-Code-Schema. Ein Prüfer hat sie aus dem Programm selbst extrahiert.
- Alle fünf Herdr-Integrationsnamen sind gültig, und Herdr schreibt nur Hook-Dateien, ohne die verlinkte Einstellungsdatei anzufassen.
- `mise install` mit ausdrücklichen Werkzeugnamen installiert genau diese, belegt im Quelltext von mise.
- Die Aussage über Fallow stimmt: das Homebrew-Paket baut nur den Kommandozeilen-Teil und liefert keinen Sprachserver mit.
- Der Aufräumvorgang von Homebrew fasst weder App-Store-Programme noch Editor-Erweiterungen an.
- Keine spätere Stufe braucht SSH, das Verschieben ans Ende ist unbedenklich.

Ein Prüfer lag falsch: Er hielt `YouTube Music` im Doctor für verwaist.
Das ist der Programmname von Pear Desktop, der Eintrag stimmt.

## Die Commits dieser Sitzung

| Commit | Inhalt |
| --- | --- |
| `2afbaa8` | Agenten-Schicht deklariert, Testsuite entfernt |
| `f930cfb` | Inventar festgelegt, ein Kanal je Werkzeug |
| `f0a1ed3` | Alle Coding-Agenten zu Homebrew, gemeinsames Editor-Set erweitert |
| `b288310` | Oh My Pi über seinen Homebrew-Tap statt npm |
| `f8d7861` | Fallow aufgenommen und die neuen Erweiterungen konfiguriert |
| `5c2e2ee` | Rosetta-Stufe entfernt, Skills ans Ende |
| `dc1b667` | Laufzeiten vor ihren Backends, Wartestellen gebündelt |
| `21c49db` | Editor-Installer repariert |
| `611eca9` | Ghostty-Dateiname und veraltete Dokumentation |
| `fcd2005` | Brewfile sortiert, Ein-Kanal-Regel präzisiert |
| `7cf963b` | Skill-Quellen selbst geholt (inzwischen überholt) |
| `eb87fae` | Probelauf zeigt echte Befehle |
| `5cd4bd9` | Probelauf repariert, Doctor an das Inventar angeglichen |
| `e83e38a` | Skills ohne Festnageln für vier Agenten |

## Was offen ist

**Drei Kanäle sind doppelt belegt.**
Für Bibliotheks-Dokumentation gibt es die `ctx7`-Regel und zusätzlich das `context7`-Plugin mit eigenem Server, die fast wortgleich dasselbe fordern.
Für Browser-Steuerung gibt es `chrome-devtools-axi`, das laut Regel exklusiv sein soll, dazu das `chrome-devtools-mcp`-Plugin und `agent-browser`.
Der Name `code-review` ist doppelt belegt, einmal aus dem Skill-Inventar und einmal aus einem Plugin, mit unterschiedlichem Verhalten.

**`mise.lock` muss beim ersten echten Lauf neu erzeugt werden.**

**Der Einrichtungsvorgang ist weiterhin nie gelaufen.**
Der Probelauf läuft vollständig durch, aber das ist keine Ausführung.
Die Reihenfolge der Stufen, das Aufräumen von Homebrew, die Wartestellen und der GitHub-Ablauf sind gelesen, nicht bewiesen.
