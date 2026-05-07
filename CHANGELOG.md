# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-07

Initial release.

### Added

- **`BeamlabLanguages.Language` struct** with six fields: `code`, `name`, `native_name`, `direction`, `has_gender`, `genders`.
- **Public API on `BeamlabLanguages`** (8 functions, all with `@spec` and doctests):
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
- **BCP 47 normalization** runs internally on every code-taking function — `"en-US"`, `"FR"`, `" fr "` all just work. Underscore separator (`"en_US"`) is also accepted.
- **54 curated languages** in `priv/data/languages.json`, covering the top-spoken languages plus all CEFR / JLPT / HSK targets.
- **Compile-time data loading** — no runtime file I/O, no GenServer, no ETS, zero runtime dependencies.

[0.1.0]: https://github.com/BeamLabEU/beamlab_languages/releases/tag/v0.1.0
