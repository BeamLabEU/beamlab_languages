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

  ## Quick start

      iex> BeamlabLanguages.has_gender?("fr")
      true

      iex> BeamlabLanguages.genders("de")
      ["m", "f", "n"]

      iex> BeamlabLanguages.direction("ar")
      :rtl

      iex> BeamlabLanguages.normalize("en-US")
      "en"

  Every function that takes a language code runs `normalize/1` on it
  internally — pass `"en-US"`, `"FR"`, or `" fr "` and lookups still work.

  ## Roadmap

  Planned for future versions and intentionally **not** in v1:
  localized language names, plural rules, articles, case marking,
  noun classes, scripts, IPA inventory, honorific levels.
  """

  alias BeamlabLanguages.Language

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
end
