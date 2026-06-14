# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-06-06

### Added

- **Language → level-system mapping** — `BeamlabLanguages.level_system/1` returns the proficiency system for a language code (`"fr"` → `"cefr"`, `"zh"` → `"hsk"`, `"ja"` → `"jlpt"`). CEFR is the default for any known language without a more specific system; Korean (`"ko"`) returns `nil` because TOPIK isn't among the curated three (a known gap). Input is normalized like every other code-taking function, so `"fr-FR"`, `"ZH-Hans-CN"`, etc. work. Unknown / `nil` input returns `nil`.
- **`language_levels/1`** — convenience for `levels(level_system(code))`: the level keys for a language in pedagogical order. Returns `[]` for languages with no curated system and for unknown codes.

## [0.4.0] - 2026-06-05

### Added

- **CEFR level on conjugation tenses** — every tense in `conjugation_paradigm/1` now carries a `:level` key (the CEFR / JLPT / HSK key at which the tense/mood is typically taught). It's a property of the tense in the language's curriculum, independent of any specific verb. All 16 French tenses are levelled A1→C2. Purely additive: existing keys are unchanged.
- **`tense_level/3`** — convenience reader that returns the level for a single `(code, mode, tense)` without walking the paradigm tree. Returns `nil` for unknown codes / modes / tenses and for tenses whose level is unknown.

## [0.3.0] - 2026-05-15

### Added

- **Proficiency level systems** — `BeamlabLanguages.level_systems/0`, `levels/1`, `level_system_label/1`, and `level_info/2` expose curated CEFR, JLPT, and HSK data. Levels are returned in pedagogical order (A1→C2, N5→N1, HSK1→HSK6). Data lives in `priv/data/levels.json` and is embedded at compile time with zero runtime dependencies.
- **Development tooling** — Added `credo` and `dialyxir` as dev dependencies. The `precommit` alias now runs `compile`, `format`, `credo`, `dialyzer`, and `test`.

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

[0.4.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.4.0
[0.3.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.3.0
[0.2.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.2.0
[0.1.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.1.0
