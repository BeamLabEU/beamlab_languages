# BEAM Lab Languages

Linguistic metadata for human languages: grammatical gender, writing direction, canonical and native names, and BCP 47 normalization. Curated, compile-time data with zero runtime dependencies.

Sibling library to [`beamlab_countries`](https://hex.pm/packages/beamlab_countries) — `beamlab_countries` knows where languages are spoken, `beamlab_languages` knows what they are like.

## What it answers

- "Does Russian use grammatical gender? If so, what genders?"
- "Is Arabic written right-to-left?"
- "What's the canonical English name of `fr`? The endonym?"
- "Does the user's locale string `en-US` collapse to a base I can use as a key?"

## Installation

```elixir
defp deps do
  [
    {:beamlab_languages, "~> 0.1"}
  ]
end
```

Then `mix deps.get`.

## Quick start

```elixir
BeamlabLanguages.has_gender?("fr")
# true

BeamlabLanguages.genders("de")
# ["m", "f", "n"]

BeamlabLanguages.direction("ar")
# :rtl

BeamlabLanguages.name("ja")
# "Japanese"

BeamlabLanguages.native_name("ja")
# "日本語"

BeamlabLanguages.normalize("en-US")
# "en"

BeamlabLanguages.get("fr")
# %BeamlabLanguages.Language{
#   code: "fr",
#   name: "French",
#   native_name: "Français",
#   direction: :ltr,
#   has_gender: true,
#   genders: ["m", "f"]
# }
```

Every function that takes a language code runs `normalize/1` internally, so `"en-US"`, `"FR"`, and `" fr "` all work. Predicates (`has_gender?/1`, `known?/1`) return `false` for `nil` or unknown input rather than raising — handy in form-validation paths.

## Documentation

Full API docs at [HexDocs](https://hexdocs.pm/beamlab_languages).

## Coverage

v1 covers 50+ languages: the top-spoken languages worldwide plus all CEFR / JLPT / HSK targets. The data lives in `priv/data/languages.json` — open a PR to add more or correct an entry.

## Roadmap (planned, not in v1)

These are intentionally deferred so v1 ships small. The v1 API is shaped to leave room for them:

- Localized language names — `BeamlabLanguages.name("fr", in: "es")` → `"francés"`
- Plural rules (CLDR categories: `:zero`, `:one`, `:two`, `:few`, `:many`, `:other`)
- Articles (definite/indefinite, by gender)
- Case marking (Slavic, Finnic, etc.)
- Noun classes (Bantu)
- Scripts / writing systems per language
- IPA inventory
- Honorific levels (Japanese / Korean)

## Non-goals

- **Not a CLDR wrapper.** No locale formatting (numbers, dates, currencies). That belongs elsewhere.
- **Not a translation API.** Knows what languages *are*; doesn't translate text.
- **No GenServer / Agent / ETS.** All data is compile-time.

## Contributing

1. Fork it
2. Create a feature branch (`git checkout -b my-new-feature`)
3. Edit `priv/data/languages.json` and/or code
4. `mix test` and `mix format`
5. Open a PR

## License

MIT — see [LICENSE.md](./LICENSE.md).
