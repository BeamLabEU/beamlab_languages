defmodule BeamlabLanguages.MixProject do
  use Mix.Project

  @source_url "https://github.com/BeamLabEU/beamlab_languages"
  @version "0.1.0"

  def project do
    [
      app: :beamlab_languages,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.39", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp aliases do
    [
      precommit: ["compile", "format", "test"]
    ]
  end

  defp package do
    [
      description:
        "Linguistic metadata for human languages: grammatical gender, writing direction, " <>
          "canonical and native names, and BCP 47 normalization. Curated, compile-time data " <>
          "with zero runtime dependencies.",
      maintainers: ["BeamLab"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv/data .formatter.exs mix.exs README.md LICENSE.md)
    ]
  end
end
