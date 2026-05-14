defmodule BeamlabLanguages do
  @moduledoc """
  Linguistic metadata for human languages.

  Answers questions like:

  - Does this language use grammatical gender? Which genders?
  - Is it written right-to-left?
  - What's the canonical English name? The endonym?
  - Can I collapse a BCP 47 tag like `"en-US"` to a base code?

  All data is curated and embedded at compile time. No runtime file I/O,
  no GenServer, no ETS, no runtime dependencies.

  ## Gender codes

  Genders are returned as strings. Consumers commonly see `"m"` (masculine),
  `"f"` (feminine), and `"n"` (neuter), but **also `"c"` (common)** for the
  Continental Scandinavian and Dutch systems where masculine and feminine
  have merged: Danish, Dutch, Norwegian Bokmål via `no`, and Swedish all
  use `["c", "n"]`. Pattern-match on all four — a `case g do "m" -> ...;
  "f" -> ...; "n" -> ... end` will silently miss those languages.

  ## Verb conjugation

  `has_verb_conjugation?/1`, `verb_groups/1`, `persons/1`, and
  `conjugation_paradigm/1` expose pedagogical conjugation metadata for
  language-learning UIs: the modes/tenses a learner is taught, the
  group system (e.g. French -er/-ir/-re), and the pronoun list.

  The contract is **"true iff we've curated a paradigm"**, not "true iff
  the language inflects verbs". So `has_verb_conjugation?("fr")` is `true`,
  `has_verb_conjugation?("zh")` is `false`, and `has_verb_conjugation?("en")`
  is also `false` until an English paradigm is curated. v0.2 ships French
  only — more languages will be added as consumers need them.

  Every label entry carries both `:label_native` (the term in the target
  language, e.g. `"Indicatif"`) and `:label_en` (the canonical English
  rendering, e.g. `"Indicative"`). Order in every list is the **teaching
  order** — opinionated and stable across versions.

  ## Quick start

      iex> BeamlabLanguages.has_gender?("fr")
      true

      iex> BeamlabLanguages.genders("de")
      ["m", "f", "n"]

      iex> BeamlabLanguages.direction("ar")
      :rtl

      iex> BeamlabLanguages.normalize("en-US")
      "en"

      iex> BeamlabLanguages.has_verb_conjugation?("fr")
      true

  Every function that takes a language code runs `normalize/1` on it
  internally — pass `"en-US"`, `"FR"`, or `" fr "` and lookups still work.

  ## Proficiency levels

  `level_systems/0`, `levels/1`, `level_system_label/1`, and
  `level_info/2` expose curated proficiency level systems (CEFR,
  JLPT, HSK) for language-learning UIs. Order is pedagogical
  (A1→C2, N5→N1, HSK1→HSK6), not alphabetical.

  ## Roadmap

  Planned for future versions and intentionally **not** in v1:
  localized language names, plural rules, articles, case marking,
  noun classes, scripts, IPA inventory, honorific levels. Verb
  conjugation paradigms ship per-language as consumers need them
  (French only as of v0.2).
  """

  alias BeamlabLanguages.Conjugation
  alias BeamlabLanguages.Language
  alias BeamlabLanguages.Levels

  @type code :: String.t()
  @type gender :: String.t()
  @type direction :: :ltr | :rtl

  @data_path Path.join([:code.priv_dir(:beamlab_languages), "data", "languages.json"])
  @external_resource @data_path

  @raw @data_path
       |> File.read!()
       |> JSON.decode!()

  # Map deprecated / regional bases to the canonical entry in the data file.
  # Real-world input from POSIX locales, glibc, and browsers emits these:
  #   - "nb" (Bokmål) and "nn" (Nynorsk) collapse to "no" (Norwegian)
  @aliases %{"nb" => "no", "nn" => "no"}

  @languages @raw
             |> Enum.map(fn {code, data} ->
               {code,
                %Language{
                  code: code,
                  name: data["name"],
                  native_name: data["native_name"],
                  direction: String.to_atom(data["direction"]),
                  has_gender: data["has_gender"],
                  genders: data["genders"]
                }}
             end)
             |> Map.new()

  @sorted_codes @languages |> Map.keys() |> Enum.sort()
  @sorted_languages Enum.map(@sorted_codes, &Map.fetch!(@languages, &1))

  @doc """
  Returns the language struct for a code, or `nil` if unknown.

  Accepts BCP 47 input — `"en-US"`, `"zh-Hans-CN"` — and sloppy casing.
  Lookups are normalized internally via `normalize/1`.

  ## Examples

      iex> BeamlabLanguages.get("fr").name
      "French"

      iex> BeamlabLanguages.get("en-US").code
      "en"

      iex> BeamlabLanguages.get("xx")
      nil

  """
  @spec get(any()) :: Language.t() | nil
  def get(code) do
    case normalize(code) do
      nil -> nil
      base -> Map.get(@languages, base)
    end
  end

  @doc """
  Lists every known language struct, sorted by code.

  Sort order is stable so the result can drive UI dropdowns without flicker.

  ## Examples

      iex> langs = BeamlabLanguages.list()
      iex> hd(langs).__struct__
      BeamlabLanguages.Language
      iex> length(langs) > 0
      true

  """
  @spec list() :: [Language.t()]
  def list, do: @sorted_languages

  @doc """
  Lists every known 2-letter base code, sorted.

  ## Examples

      iex> "en" in BeamlabLanguages.list_codes()
      true

      iex> codes = BeamlabLanguages.list_codes()
      iex> codes == Enum.sort(codes)
      true

  """
  @spec list_codes() :: [code()]
  def list_codes, do: @sorted_codes

  @doc """
  Returns true iff the language uses grammatical gender.

  Returns `false` for unknown / `nil` / non-string input rather than
  raising — callers (form validation, template rendering) often pass
  whatever they received from the user.

  ## Examples

      iex> BeamlabLanguages.has_gender?("fr")
      true

      iex> BeamlabLanguages.has_gender?("en")
      false

      iex> BeamlabLanguages.has_gender?("xx")
      false

  """
  @spec has_gender?(any()) :: boolean()
  def has_gender?(code) do
    case get(code) do
      %Language{has_gender: g} -> g
      nil -> false
    end
  end

  @doc """
  Returns the list of gender codes a language uses.

  Returns `[]` for languages without grammatical gender, and `[]` for
  unknown codes.

  ## Examples

      iex> BeamlabLanguages.genders("fr")
      ["m", "f"]

      iex> BeamlabLanguages.genders("de")
      ["m", "f", "n"]

      iex> BeamlabLanguages.genders("en")
      []

  """
  @spec genders(any()) :: [gender()]
  def genders(code) do
    case get(code) do
      %Language{genders: g} -> g
      nil -> []
    end
  end

  @doc """
  Returns the writing direction.

  Returns `:ltr` for unknown codes — the safe default for most rendering
  contexts where an unknown language shouldn't flip the page layout.

  ## Examples

      iex> BeamlabLanguages.direction("ar")
      :rtl

      iex> BeamlabLanguages.direction("en")
      :ltr

      iex> BeamlabLanguages.direction("xx")
      :ltr

  """
  @spec direction(any()) :: direction()
  def direction(code) do
    case get(code) do
      %Language{direction: d} -> d
      nil -> :ltr
    end
  end

  @doc """
  Canonical English name of the language. Returns `nil` for unknown codes.

  ## Examples

      iex> BeamlabLanguages.name("fr")
      "French"

      iex> BeamlabLanguages.name("ja")
      "Japanese"

      iex> BeamlabLanguages.name("xx")
      nil

  """
  @spec name(any()) :: String.t() | nil
  def name(code) do
    case get(code) do
      %Language{name: n} -> n
      nil -> nil
    end
  end

  @doc """
  Native (endonym) name of the language — what speakers call it themselves.

  Returns `nil` for unknown codes.

  ## Examples

      iex> BeamlabLanguages.native_name("fr")
      "Français"

      iex> BeamlabLanguages.native_name("ja")
      "日本語"

      iex> BeamlabLanguages.native_name("xx")
      nil

  """
  @spec native_name(any()) :: String.t() | nil
  def native_name(code) do
    case get(code) do
      %Language{native_name: n} -> n
      nil -> nil
    end
  end

  @doc """
  Normalizes a language input string to a 2-letter base code.

  - Strips dialect tags (`"en-US"` → `"en"`, `"zh-Hans-CN"` → `"zh"`)
  - Accepts `_` as a separator too (`"en_US"` → `"en"`)
  - Lowercases (`"FR"` → `"fr"`)
  - Trims whitespace
  - Maps deprecated / regional bases to their canonical entry: `"nb"`
    (Bokmål) and `"nn"` (Nynorsk) collapse to `"no"` (Norwegian)
  - Returns `nil` if no plausible 2-letter base can be extracted

  This is what every other function calls internally before looking up
  a code, so consumers never need to normalize before calling `get/1`,
  `name/1`, etc. — but it's exposed because consumers sometimes need
  the bare base code for their own purposes.

  ## Examples

      iex> BeamlabLanguages.normalize("en-US")
      "en"

      iex> BeamlabLanguages.normalize("FR")
      "fr"

      iex> BeamlabLanguages.normalize("zh-Hans-CN")
      "zh"

      iex> BeamlabLanguages.normalize("nb-NO")
      "no"

      iex> BeamlabLanguages.normalize("")
      nil

      iex> BeamlabLanguages.normalize(nil)
      nil

  """
  @spec normalize(any()) :: code() | nil
  def normalize(input) when is_binary(input) do
    input
    |> String.trim()
    |> String.downcase()
    |> String.split(["-", "_"], parts: 2)
    |> hd()
    |> base_or_nil()
    |> dealias()
  end

  def normalize(_), do: nil

  defp base_or_nil(<<a, b>>) when a in ?a..?z and b in ?a..?z, do: <<a, b>>
  defp base_or_nil(_), do: nil

  defp dealias(nil), do: nil
  defp dealias(base), do: Map.get(@aliases, base, base)

  @doc """
  Returns true iff the code maps to a known language.

  Sugar over `get/1`. Returns `false` for unknown / `nil` / non-string input.

  ## Examples

      iex> BeamlabLanguages.known?("fr")
      true

      iex> BeamlabLanguages.known?("en-US")
      true

      iex> BeamlabLanguages.known?("xx")
      false

  """
  @spec known?(any()) :: boolean()
  def known?(code), do: get(code) != nil

  @doc """
  Returns true iff a verb conjugation paradigm is curated for the language.

  The contract is data-driven: returns `true` exactly when
  `conjugation_paradigm/1` would return non-`nil` for the same code.
  English and Swedish technically inflect verbs but currently return
  `false` — they have no curated paradigm yet.

  Returns `false` for unknown / `nil` / non-string input.

  ## Examples

      iex> BeamlabLanguages.has_verb_conjugation?("fr")
      true

      iex> BeamlabLanguages.has_verb_conjugation?("zh")
      false

      iex> BeamlabLanguages.has_verb_conjugation?("xx")
      false

  """
  @spec has_verb_conjugation?(any()) :: boolean()
  def has_verb_conjugation?(code) do
    case normalize(code) do
      nil -> false
      base -> Conjugation.has_paradigm?(base)
    end
  end

  @doc """
  Returns the pedagogical verb groups for a language, or `nil`.

  Verb groups are the curriculum buckets used to teach conjugation
  (French's -er / -ir / -re, Spanish's -ar / -er / -ir, etc.). Each
  entry is a map with `:key`, `:label_native` (target language), and
  `:label_en` (English).

  Returns `nil` when no paradigm is curated, **and also** when the
  language has a paradigm but no meaningful pedagogical group system.

  ## Examples

      iex> groups = BeamlabLanguages.verb_groups("fr")
      iex> length(groups)
      3
      iex> hd(groups)
      %{key: "1", label_native: "1er groupe (verbes en -er)", label_en: "1st group (-er verbs)"}

      iex> BeamlabLanguages.verb_groups("zh")
      nil

      iex> BeamlabLanguages.verb_groups("xx")
      nil

  """
  @spec verb_groups(any()) :: [map()] | nil
  def verb_groups(code) do
    case normalize(code) do
      nil -> nil
      base -> Conjugation.verb_groups(base)
    end
  end

  @doc """
  Returns the person/pronoun list for a language's conjugation, or `nil`.

  Each entry is a map with `:key` (a stable identifier like `"1sg"` or
  `"3pl"`), `:label_native` (the pronoun in the target language), and
  `:label_en` (the English gloss, useful for learner UIs).

  The set of person keys may vary by language — a future Slovenian entry
  would add a dual, Arabic would split 2nd person by gender, etc. Don't
  assume a fixed six-person shape.

  Returns `nil` for languages without a curated paradigm.

  ## Examples

      iex> persons = BeamlabLanguages.persons("fr")
      iex> length(persons)
      6
      iex> hd(persons)
      %{key: "1sg", label_native: "je", label_en: "I"}

      iex> BeamlabLanguages.persons("zh")
      nil

  """
  @spec persons(any()) :: [map()] | nil
  def persons(code) do
    case normalize(code) do
      nil -> nil
      base -> Conjugation.persons(base)
    end
  end

  @doc """
  Returns the conjugation paradigm — modes and their tenses — or `nil`.

  Shape: `%{modes: [%{key, label_native, label_en, tenses: [%{key,
  label_native, label_en}, ...]}, ...]}`. Order of modes and tenses is
  the **teaching order** — opinionated and stable across versions.

  Persons live separately under `persons/1`, not inside the paradigm,
  so the same paradigm can be paired with the language's pronoun list
  in the consumer UI.

  Returns `nil` for languages without a curated paradigm.

  ## Examples

      iex> paradigm = BeamlabLanguages.conjugation_paradigm("fr")
      iex> length(paradigm.modes)
      4
      iex> [first | _] = paradigm.modes
      iex> first.key
      "indicatif"
      iex> first.label_native
      "Indicatif"
      iex> first.label_en
      "Indicative"
      iex> length(first.tenses)
      8

      iex> BeamlabLanguages.conjugation_paradigm("zh")
      nil

  """
  @spec conjugation_paradigm(any()) :: map() | nil
  def conjugation_paradigm(code) do
    case normalize(code) do
      nil -> nil
      base -> Conjugation.paradigm(base)
    end
  end

  @doc """
  Lists every known proficiency level system key, sorted.

  ## Examples

      iex> "cefr" in BeamlabLanguages.level_systems()
      true

      iex> BeamlabLanguages.level_systems() == Enum.sort(BeamlabLanguages.level_systems())
      true

  """
  @spec level_systems() :: [String.t()]
  def level_systems, do: Levels.systems()

  @doc """
  Lists the levels for a proficiency system, in pedagogical order.

  Returns `[]` for unknown systems.

  ## Examples

      iex> BeamlabLanguages.levels("cefr")
      ["A1", "A2", "B1", "B2", "C1", "C2"]

      iex> BeamlabLanguages.levels("jlpt")
      ["N5", "N4", "N3", "N2", "N1"]

      iex> BeamlabLanguages.levels("unknown")
      []

  """
  @spec levels(String.t()) :: [String.t()]
  def levels(system), do: Levels.level_keys(system)

  @doc """
  Returns the human-readable label for a proficiency system.

  Returns `nil` for unknown systems.

  ## Examples

      iex> BeamlabLanguages.level_system_label("cefr")
      "CEFR"

      iex> BeamlabLanguages.level_system_label("hsk")
      "HSK"

      iex> BeamlabLanguages.level_system_label("unknown")
      nil

  """
  @spec level_system_label(String.t()) :: String.t() | nil
  def level_system_label(system), do: Levels.label(system)

  @doc """
  Returns metadata for a single level within a system.

  Returns `nil` for unknown systems or unknown levels.

  ## Examples

      iex> BeamlabLanguages.level_info("cefr", "A1")
      %{key: "A1", label: "A1", description: "Beginner"}

      iex> BeamlabLanguages.level_info("cefr", "Z9")
      nil

      iex> BeamlabLanguages.level_info("unknown", "A1")
      nil

  """
  @spec level_info(String.t(), String.t()) :: map() | nil
  def level_info(system, level_key), do: Levels.level_info(system, level_key)
end
