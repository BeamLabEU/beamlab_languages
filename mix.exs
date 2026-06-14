defmodule BeamlabLanguages.MixProject do
  use Mix.Project

  @source_url "https://github.com/BeamLabEU/beamlab_languages"
  @version "0.6.0"

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
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp aliases do
    [
      precommit: ["compile", "format", "credo", "dialyzer", "test"]
    ]
  end

  defp package do
    [
      description:
        "Linguistic metadata for human languages: grammatical gender, writing direction, " <>
          "canonical and native names, BCP 47 normalization, and pedagogical verb " <>
          "conjugation paradigms. Curated, compile-time data with zero runtime dependencies.",
      maintainers: ["BeamLab"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv/data .formatter.exs mix.exs README.md LICENSE.md CHANGELOG.md)
    ]
  end
end
