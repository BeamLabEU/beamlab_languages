# Agent Guide for beamlab_languages

## Project Overview

`beamlab_languages` is an Elixir library providing curated linguistic metadata for human languages. It is a **compile-time data library** with zero runtime dependencies, no GenServer, no ETS, and no runtime file I/O.

- **Language**: Elixir (requires `~> 1.18`)
- **Package manager**: Mix
- **Source**: `https://github.com/BeamLabEU/beamlab_languages`
- **License**: MIT
- **Version**: See `mix.exs` (`@version`)

## Key Characteristics

- All data is embedded at compile time from JSON files in `priv/data/`.
- The public API lives in `BeamlabLanguages` (`lib/beamlab_languages.ex`).
- Supporting modules are `BeamlabLanguages.Language` (struct) and `BeamlabLanguages.Conjugation` (compile-time loader).
- Every function that takes a language code normalizes it internally via `normalize/1`.
- Predicates (`has_gender?/1`, `known?/1`, `has_verb_conjugation?/1`) return `false` for unknown/`nil`/non-string input rather than raising.
- `direction/1` returns `:ltr` for unknown codes (safe default for rendering).

## Build & Test Commands

```bash
# Install dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Format code
mix format

# Run all pre-commit checks (compile + format + test)
mix precommit
```

## Project Structure

```
lib/
  beamlab_languages.ex              # Public API
  beamlab_languages/
    language.ex                     # %Language{} struct
    conjugation.ex                  # Compile-time conjugation loader
priv/data/
  languages.json                    # Core language metadata (54+ languages)
  conjugation/
    fr.json                         # Per-language conjugation paradigms
test/
  beamlab_languages_test.exs        # Main test suite (doctests + unit tests)
```

## Data Files

### `priv/data/languages.json`

A JSON object keyed by 2-letter ISO 639-1 codes. Each value is an object with:

- `name` (string) — canonical English name
- `native_name` (string) — endonym
- `direction` (string) — `"ltr"` or `"rtl"`
- `has_gender` (boolean)
- `genders` (list of strings) — e.g. `["m", "f"]`, `["m", "f", "n"]`, `["c", "n"]`

**Important**: The `"c"` (common) gender is real and used by Danish, Dutch, Norwegian (`no`), and Swedish. Do not assume only `"m"`, `"f"`, `"n"` exist.

### `priv/data/conjugation/<code>.json`

Per-language conjugation paradigms. Schema (as of v0.2):

```json
{
  "verb_groups": [
    {"key": "...", "label_native": "...", "label_en": "..."}
  ],
  "persons": [
    {"key": "...", "label_native": "...", "label_en": "..."}
  ],
  "paradigm": {
    "modes": [
      {
        "key": "...",
        "label_native": "...",
        "label_en": "...",
        "tenses": [
          {"key": "...", "label_native": "...", "label_en": "..."}
        ]
      }
    ]
  }
}
```

- `verb_groups` may be `null` if the language has a paradigm but no pedagogical group system.
- Order of `modes` and `tenses` is **teaching order** — opinionated and must stay stable across versions.
- Every label entry must have both `label_native` and `label_en`.

## Adding or Updating Data

1. Edit the relevant JSON file(s).
2. Run `mix test` to verify.
3. Run `mix format` if you edited `.ex` files.
4. Update `CHANGELOG.md` under `## [Unreleased]` or the appropriate version section.

**Do not** bump the version in `mix.exs` unless explicitly asked.

## Code Conventions

- All public functions in `BeamlabLanguages` have `@spec` and doctests.
- Use `String.t()` and `boolean()` in specs, not `binary()` / `bool()`.
- Pattern-match on the `%Language{}` struct in function bodies; do not access fields directly via map syntax in public API functions.
- Conjugation functions delegate to `BeamlabLanguages.Conjugation`; do not inline that logic.
- Normalize input via `normalize/1` before any lookup. Return safe defaults (`false`, `nil`, `[]`, `:ltr`) for invalid input.
- Gender codes are strings (`"m"`, `"f"`, `"n"`, `"c"`), not atoms.

## Architecture Notes

- `BeamlabLanguages` reads `priv/data/languages.json` at compile time via `@external_resource`. Editing the JSON triggers automatic recompilation.
- `BeamlabLanguages.Conjugation` reads all `priv/data/conjugation/*.json` files at compile time. Each file is also declared as `@external_resource`.
- The `@aliases` module attribute maps deprecated/regional codes (`"nb"`, `"nn"`) to canonical ones (`"no"`).
- There is intentionally no runtime configuration, no ETS caching, and no dynamic code loading.

## Testing Guidelines

- Tests are in `test/beamlab_languages_test.exs`.
- Doctests are enabled (`doctest BeamlabLanguages`).
- Tests are `async: true`.
- When adding new language data, add tests covering:
  - The new code is returned by `list_codes/0`
  - `get/1`, `name/1`, `native_name/1`, `direction/1`, `has_gender?/1`, `genders/1` return expected values
  - If adding conjugation data: `has_verb_conjugation?/1`, `verb_groups/1`, `persons/1`, `conjugation_paradigm/1`
- The existing "data integrity" test verifies every entry has all required fields and valid values.

## Things to Avoid

- Do not add runtime dependencies. This library ships with zero.
- Do not add GenServer, Agent, or ETS. All data is compile-time.
- Do not change the shape of existing JSON schemas without updating both the Elixir code that reads them and the tests.
- Do not break the safe-default contract: unknown/`nil`/non-string input must not raise for predicates.
- Do not remove or rename public functions without a major version bump.
