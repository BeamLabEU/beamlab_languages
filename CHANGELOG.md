# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-08

### Added

- **Pedagogical verb conjugation metadata** — four new functions on `BeamlabLanguages`:
  - `has_verb_conjugation?/1` — `true` iff a paradigm is curated for the language. Data-driven contract: stays in sync with `conjugation_paradigm/1`. Returns `false` for uncurated languages even when they technically inflect verbs (English, Swedish, etc.) until paradigms are added.
  - `verb_groups/1` — pedagogical group system (e.g. French's `-er` / `-ir` / `-re`), or `nil` when no paradigm exists OR when the language has a paradigm but no meaningful group system.
  - `persons/1` — person/pronoun list with stable keys (`"1sg"` … `"3pl"` for French; future languages may add dual or gender-split persons).
  - `conjugation_paradigm/1` — modes-and-tenses tree. Order is **teaching order**, opinionated and stable across versions.
- **`label_native` + `label_en` convention** — every mode, tense, group, and person carries both labels: the term in the target language (`"Indicatif"`) and the canonical English rendering (`"Indicative"`). Useful for learner UIs that show either side of a translation.
- **French paradigm** in `priv/data/conjugation/fr.json`: 3 verb groups, 6 persons, 4 modes (indicatif / subjonctif / conditionnel / impératif) covering 16 tenses total.
- **Per-language data files** under `priv/data/conjugation/<code>.json`. Each file is read at compile time as an `@external_resource`, so edits trigger recompile with no runtime I/O.

### Notes

- v0.2 ships French only. More languages will land as consumers need them; the schema is intentionally not locked in for non-Romance / non-Indo-European paradigms (Russian aspect pairs, Arabic stems, Slovenian dual, etc.) — those may extend the shape.

[0.2.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.2.0

## [0.1.0] - 2026-05-07

Initial release.

### Added

- **`BeamlabLanguages.Language` struct** with six fields: `code`, `name`, `native_name`, `direction`, `has_gender`, `genders`.
- **Public API on `BeamlabLanguages`** (10 functions, all with `@spec` and doctests):
  - `get/1` — fetch a `Language` struct by code, or `nil`
  - `list/0` — every known language, sorted by code
  - `list_codes/0` — every known 2-letter base code, sorted
  - `has_gender?/1` — predicate, `false` for unknown / `nil`
  - `genders/1` — gender list, `[]` for unknown / non-gendered languages
  - `direction/1` — `:ltr` or `:rtl`, `:ltr` for unknown
  - `name/1` — canonical English name, or `nil`
  - `native_name/1` — endonym, or `nil`
  - `normalize/1` — collapse BCP 47 / sloppy casing to a 2-letter base
  - `known?/1` — sugar over `get/1`
- **BCP 47 normalization** runs internally on every code-taking function — `"en-US"`, `"FR"`, `" fr "` all just work. Underscore separator (`"en_US"`) is also accepted, and `"nb"` / `"nn"` (Bokmål / Nynorsk, as emitted by POSIX locales and browsers) collapse to `"no"`.
- **54 curated languages** in `priv/data/languages.json`, covering the top-spoken languages plus all CEFR / JLPT / HSK targets.
- **Compile-time data loading** — no runtime file I/O, no GenServer, no ETS, zero runtime dependencies.

[0.1.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.1.0
