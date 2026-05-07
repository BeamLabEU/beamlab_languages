defmodule BeamlabLanguages.Language do
  @moduledoc """
  Struct describing a single language.

  ## Fields

  - `code` - ISO 639-1 two-letter base code (e.g. `"en"`, `"fr"`)
  - `name` - canonical English name (e.g. `"French"`)
  - `native_name` - endonym / what speakers call it themselves (e.g. `"Français"`)
  - `direction` - writing direction, `:ltr` or `:rtl`
  - `has_gender` - whether the language uses grammatical gender
  - `genders` - list of gender codes the language uses; `[]` when `has_gender` is `false`.
    Common values are `"m"` (masculine), `"f"` (feminine), `"n"` (neuter), and **`"c"`
    (common)** — used by Danish, Dutch, Norwegian, and Swedish, where masculine
    and feminine have merged into a single common gender. Pattern-match all four.

  ## Examples

      iex> BeamlabLanguages.get("fr")
      %BeamlabLanguages.Language{
        code: "fr",
        name: "French",
        native_name: "Français",
        direction: :ltr,
        has_gender: true,
        genders: ["m", "f"]
      }

  """

  defstruct [:code, :name, :native_name, :direction, :has_gender, :genders]

  @type t :: %__MODULE__{
          code: BeamlabLanguages.code(),
          name: String.t(),
          native_name: String.t(),
          direction: BeamlabLanguages.direction(),
          has_gender: boolean(),
          genders: [BeamlabLanguages.gender()]
        }
end
