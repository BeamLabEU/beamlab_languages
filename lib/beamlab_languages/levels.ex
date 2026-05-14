defmodule BeamlabLanguages.Levels do
  @moduledoc false

  # Compile-time loader for proficiency level systems.
  #
  # Reads priv/data/levels.json at compile time and embeds it as module
  # attributes — no runtime file I/O.
  #
  # The public API lives on BeamlabLanguages and delegates here.

  @path Path.join([:code.priv_dir(:beamlab_languages), "data", "levels.json"])
  @external_resource @path

  @raw @path
       |> File.read!()
       |> JSON.decode!()

  to_level = fn %{"key" => k, "label" => l, "description" => d} ->
    %{key: k, label: l, description: d}
  end

  @systems @raw
           |> Enum.map(fn {key, data} ->
             levels = Enum.map(data["levels"], to_level)

             {key,
              %{
                label: data["label"],
                level_keys: Enum.map(levels, & &1.key),
                levels: levels
              }}
           end)
           |> Map.new()

  @system_keys @systems |> Map.keys() |> Enum.sort()

  @spec systems() :: [String.t()]
  def systems, do: @system_keys

  @spec label(String.t()) :: String.t() | nil
  def label(system) do
    case Map.get(@systems, system) do
      nil -> nil
      data -> data.label
    end
  end

  @spec level_keys(String.t()) :: [String.t()]
  def level_keys(system) do
    case Map.get(@systems, system) do
      nil -> []
      data -> data.level_keys
    end
  end

  @spec level_info(String.t(), String.t()) :: map() | nil
  def level_info(system, level_key) do
    case Map.get(@systems, system) do
      nil -> nil
      data -> Enum.find(data.levels, &(&1.key == level_key))
    end
  end
end
