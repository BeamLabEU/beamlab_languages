defmodule BeamlabLanguages.Reflexive do
  @moduledoc false

  # Per-language rules for recognising a reflexive / pronominal verb from its
  # lemma. Unlike paradigms and levels, these are morphological *rules*, not
  # curated data, so they live in code as pattern-matched function heads rather
  # than in priv/data.
  #
  # The public API lives on `BeamlabLanguages` and delegates here. The caller
  # normalises the language code; the lemma is lowercased and trimmed here so
  # callers can pass it straight through from user input or a database column.

  @spec reflexive?(String.t(), any()) :: boolean()
  def reflexive?(lang, lemma) when is_binary(lemma) do
    marked?(lang, lemma |> String.trim() |> String.downcase())
  end

  def reflexive?(_lang, _lemma), do: false

  # French pronominal infinitives carry a leading reflexive pronoun: "se laver",
  # "se souvenir", and the elided "s'appeler", "s'asseoir". The trailing space
  # after "se" is load-bearing — without it "semer", "sentir", "servir" would
  # be misread as reflexive.
  defp marked?("fr", lemma), do: String.starts_with?(lemma, ["se ", "s'", "s’"])

  # Italian reflexive infinitives attach the clitic -si to the infinitive,
  # which always yields an "-rsi" ending: "chiamarsi", "mettersi", "vestirsi",
  # "porsi", "condursi". (This is exactly the case the French-only "se "/"s'"
  # rule used to miss.)
  defp marked?("it", lemma), do: String.ends_with?(lemma, "rsi")

  defp marked?(_lang, _lemma), do: false
end
