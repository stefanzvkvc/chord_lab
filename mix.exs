defmodule ChordLab.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :chord_lab,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "ChordLab",
      description: description(),
      source_url: "https://github.com/stefanzvkvc/chord_lab"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ChordLab.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:chord, "~> 0.1.2"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.7"}
    ]
  end

  defp package do
    [
      maintainers: ["Stefan Zivkovic"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/stefanzvkvc/chord_lab"},
      categories: [
        "Testing Tools",
        "Real-Time Applications",
        "LiveView Examples",
        "Developer Tools"
      ],
      keywords: [
        "elixir",
        "phoenix liveview",
        "chord",
        "testing",
        "real-time",
        "state synchronization",
        "chat application",
        "delta sync",
        "pubsub",
        "collaboration tools"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp description do
    """
    ChordLab is a test tool for the Chord library. It currently supports testing chat functionality, with plans to support testing video calls, game sessions, and more in the future.
    """
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind chord_lab", "esbuild chord_lab"],
      "assets.deploy": [
        "tailwind chord_lab --minify",
        "esbuild chord_lab --minify",
        "phx.digest"
      ]
    ]
  end
end
