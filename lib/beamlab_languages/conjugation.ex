defmodule BeamlabLanguages.Conjugation do
  @moduledoc false

  # Compile-time loader for verb conjugation paradigms.
  #
  # Each `priv/data/conjugation/<code>.json` file describes one language's
  # paradigm: pedagogical group system, person/pronoun list, and the
  # mode/tense tree. Files are read at compile time and embedded as a
  # module attribute — no runtime file I/O.
  #
  # The public API lives on `BeamlabLanguages` and delegates here.

  @dir Path.join([:code.priv_dir(:beamlab_languages), "data", "conjugation"])

  @files (case File.ls(@dir) do
            {:ok, files} ->
              files
              |> Enum.filter(&String.ends_with?(&1, ".json"))
              |> Enum.sort()

            {:error, _} ->
              []
          end)

  for file <- @files do
    @external_resource Path.join(@dir, file)
  end

  to_label_item = fn %{"key" => k, "label_native" => ln, "label_en" => le} ->
    %{key: k, label_native: ln, label_en: le}
  end

  to_mode = fn %{
                 "key" => k,
                 "label_native" => ln,
                 "label_en" => le,
                 "tenses" => tenses
               } ->
    %{
      key: k,
      label_native: ln,
      label_en: le,
      tenses: Enum.map(tenses, to_label_item)
    }
  end

  to_paradigm = fn %{"modes" => modes} ->
    %{modes: Enum.map(modes, to_mode)}
  end

  to_groups = fn
    nil -> nil
    list -> Enum.map(list, to_label_item)
  end

  @data @files
        |> Enum.map(fn file ->
          code = Path.basename(file, ".json")
          path = Path.join(@dir, file)
          raw = path |> File.read!() |> JSON.decode!()

          {code,
           %{
             verb_groups: to_groups.(raw["verb_groups"]),
             persons: Enum.map(raw["persons"], to_label_item),
             paradigm: to_paradigm.(raw["paradigm"])
           }}
        end)
        |> Map.new()

  @spec has_paradigm?(String.t()) :: boolean()
  def has_paradigm?(code), do: Map.has_key?(@data, code)

  @spec verb_groups(String.t()) :: [map()] | nil
  def verb_groups(code) do
    case Map.get(@data, code) do
      nil -> nil
      data -> data.verb_groups
    end
  end

  @spec persons(String.t()) :: [map()] | nil
  def persons(code) do
    case Map.get(@data, code) do
      nil -> nil
      data -> data.persons
    end
  end

  @spec paradigm(String.t()) :: map() | nil
  def paradigm(code) do
    case Map.get(@data, code) do
      nil -> nil
      data -> data.paradigm
    end
  end
end
