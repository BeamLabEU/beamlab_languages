# Task: add an Italian verb-conjugation paradigm to `beamlab_languages`

**For:** the agent maintaining the `beamlab_languages` package.
**Why:** Langust just seeded Italian A1 vocabulary (111 A1 verbs among them), but
`BeamlabLanguages.conjugation_paradigm("it")` returns `nil` — only French has a paradigm.
With no paradigm, `Langust.Vocabulary.generate_conjugation/3` produces nothing for Italian
verbs, so there's no conjugation practice. Adding the paradigm unblocks it.

## What the package does today

Paradigms are data-driven and compile-time-embedded. `BeamlabLanguages.Conjugation` reads
every `priv/data/conjugation/<code>.json` at compile time into a module attribute (no
runtime I/O) and exposes them via `has_verb_conjugation?/1`, `verb_groups/1`, `persons/1`,
`conjugation_paradigm/1`, `tense_level/3`. Today only `fr.json` exists.

**So the entire change is: add `priv/data/conjugation/it.json`, then publish a new
package version.** No Elixir code changes — the loader picks the file up by glob.

## File schema (from the loader + `fr.json`)

Top-level keys: `verb_groups` (list, may be `null`), `persons` (list, **required**),
`paradigm` → `modes` (list). Each item shape:

- verb_group / person: `{"key", "label_native", "label_en"}`
- mode: `{"key", "label_native", "label_en", "tenses": [...]}`
- tense: `{"key", "label_native", "label_en", "level"}` — `level` is a CEFR key
  (`"A1"`…`"C2"`); omit ⇒ `nil` (unknown). **`level` is load-bearing:** Langust's
  level-scoped generation (`generate_conjugation(verb, endpoint, levels: ["A1"])`) selects
  exactly the tenses whose `level` is in the set. If no tense is marked `"A1"`, A1
  generation produces nothing.

### Contract notes / gotchas

- **Keep the person keys `1sg/2sg/3sg/1pl/2pl/3pl`.** Conjugation forms are stored keyed by
  person and filtered on `{mode, tense, person}`; reusing the same six slots as French keeps
  the consumer code unchanged. Only the labels change (io/tu/lui-lei/noi/voi/loro).
- Italian formal address (*Lei*) reuses the 3sg form — no extra person slot.
- The imperative has no 1sg form; that's expected (the generator/LLM just won't fill it).
- `verb_group` on a word is `max length 8`; `"1"`/`"2"`/`"3"` is fine.
- Tense `key`s are free-form strings compared by the app — `"presente"`, `"passato_prossimo"`
  etc. are all fine; they don't need to match French.

## Ready-to-use `priv/data/conjugation/it.json`

Authored to standard Italian grammar. CEFR levels are sensible curriculum placements and
**may be adjusted** by the maintainer — the only hard requirement for Langust's current
state is that `indicativo/presente` and `imperativo/presente` are `"A1"` (that's the A1
verb seed's scope, mirroring French A1 = present indicative + present imperative).

```json
{
  "verb_groups": [
    {"key": "1", "label_native": "1ª coniugazione (verbi in -are)", "label_en": "1st conjugation (-are verbs)"},
    {"key": "2", "label_native": "2ª coniugazione (verbi in -ere)", "label_en": "2nd conjugation (-ere verbs)"},
    {"key": "3", "label_native": "3ª coniugazione (verbi in -ire)", "label_en": "3rd conjugation (-ire verbs)"}
  ],
  "persons": [
    {"key": "1sg", "label_native": "io", "label_en": "I"},
    {"key": "2sg", "label_native": "tu", "label_en": "you (familiar)"},
    {"key": "3sg", "label_native": "lui/lei", "label_en": "he/she"},
    {"key": "1pl", "label_native": "noi", "label_en": "we"},
    {"key": "2pl", "label_native": "voi", "label_en": "you (plural)"},
    {"key": "3pl", "label_native": "loro", "label_en": "they"}
  ],
  "paradigm": {
    "modes": [
      {
        "key": "indicativo",
        "label_native": "Indicativo",
        "label_en": "Indicative",
        "tenses": [
          {"key": "presente",            "label_native": "Presente",            "label_en": "Present",          "level": "A1"},
          {"key": "passato_prossimo",    "label_native": "Passato prossimo",    "label_en": "Present perfect",  "level": "A2"},
          {"key": "imperfetto",          "label_native": "Imperfetto",          "label_en": "Imperfect",        "level": "A2"},
          {"key": "futuro_semplice",     "label_native": "Futuro semplice",     "label_en": "Simple future",    "level": "A2"},
          {"key": "trapassato_prossimo", "label_native": "Trapassato prossimo", "label_en": "Pluperfect",       "level": "B1"},
          {"key": "futuro_anteriore",    "label_native": "Futuro anteriore",    "label_en": "Future perfect",   "level": "B1"},
          {"key": "passato_remoto",      "label_native": "Passato remoto",      "label_en": "Preterite",        "level": "B2"},
          {"key": "trapassato_remoto",   "label_native": "Trapassato remoto",   "label_en": "Past anterior",    "level": "C1"}
        ]
      },
      {
        "key": "congiuntivo",
        "label_native": "Congiuntivo",
        "label_en": "Subjunctive",
        "tenses": [
          {"key": "presente",   "label_native": "Presente",   "label_en": "Present",    "level": "B1"},
          {"key": "passato",    "label_native": "Passato",    "label_en": "Past",       "level": "B2"},
          {"key": "imperfetto", "label_native": "Imperfetto", "label_en": "Imperfect",  "level": "B2"},
          {"key": "trapassato", "label_native": "Trapassato", "label_en": "Pluperfect", "level": "C1"}
        ]
      },
      {
        "key": "condizionale",
        "label_native": "Condizionale",
        "label_en": "Conditional",
        "tenses": [
          {"key": "presente", "label_native": "Presente", "label_en": "Present", "level": "A2"},
          {"key": "passato",  "label_native": "Passato",  "label_en": "Past",    "level": "B1"}
        ]
      },
      {
        "key": "imperativo",
        "label_native": "Imperativo",
        "label_en": "Imperative",
        "tenses": [
          {"key": "presente", "label_native": "Presente", "label_en": "Present", "level": "A1"}
        ]
      }
    ]
  }
}
```

## Steps for the package maintainer

1. Add the file above as `priv/data/conjugation/it.json` in the `beamlab_languages` repo.
2. Sanity-check it loads: `BeamlabLanguages.has_verb_conjugation?("it")` → `true`,
   `conjugation_paradigm("it").modes |> length()` → `4`,
   `tense_level("it", "indicativo", "presente")` → `"A1"`.
   (`persons/1` and `verb_groups/1` non-nil with 6 and 3 entries.)
3. Bump the package version and publish to Hex (current: 0.5.0).

## Downstream in the Langust app (separate, after publish)

1. Bump `{:beamlab_languages, "~> <new>"}` in `mix.exs`, `mix deps.get`.
2. **`mix compile --force`** (the paradigm is embedded at compile time) **+ restart elixir**
   — otherwise the running BEAM keeps the old embedded data.
3. Verify in-app: `BeamlabLanguages.conjugation_paradigm("it")` non-nil.
4. Generate A1 conjugations for the 111 Italian A1 verbs, e.g. per verb
   `Langust.Vocabulary.generate_conjugation(verb, endpoint_uuid, levels: ["A1"])`
   (LLM-backed; fills + translates forms), and check coverage with
   `Langust.Vocabulary.conjugation_coverage("it", levels: ["A1"])`.

This last step is Langust-side content generation, not part of the package change — listed
so the handoff is complete.
