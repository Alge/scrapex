defmodule Scrapex.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrapex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      aliases: aliases(),
      releases: releases(),

      # Balanced Dialyzer settings (not maximum strictness)
      dialyzer: [
        flags: [
          # Catch unhandled errors (important)
          :error_handling,
          # Unknown functions/types (important)
          :unknown,
          # Ignored return values (helpful)
          :unmatched_returns
          # Removed: :underspecs, :overspecs, :specdiffs (too picky for dev)
          # Removed: :race_conditions (too slow for regular use)
        ],
        # Don't halt on warnings during development
        halt_exit_status: false
      ],

      # Reasonable compiler options
      elixirc_options: [
        debug_info: true
        # Removed: warnings_as_errors (too strict for daily dev)
        # Removed: all_warnings (default warnings are fine)
      ],

      # Test coverage settings
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "test.one": :test
      ]
    ]
  end

  defp escript do
    [
      main_module: Scrapex.CLI,
      name: "scrapex"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Safety and quality tools
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: [:test], runtime: false},
      {:castore, "~> 1.0", only: [:test], runtime: false},

      # Documentation (optional)
      {:ex_doc, "~> 0.31", only: [:dev, :test], runtime: false},

      # Building binaries
      {:burrito, "~> 1.0.0"}
    ]
  end

  defp aliases do
    [
      # Standard Elixir workflows
      test: ["test"],
      format: ["format"],
      deps: ["deps.get", "deps.compile"],

      # Quality checks (simplified)
      check: [
        "format --check-formatted",
        "credo --strict",
        "test"
      ],
      "check.strict": [
        "check",
        "dialyzer",
        "sobelow"
      ],
      "check.ci": [
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "dialyzer --halt-exit-status",
        "sobelow --exit",
        "test --warnings-as-errors",
        "coveralls --minimum-coverage 80"
      ],
      "test.one": ["test --max-failures 1 --seed 0"]
    ]
  end

  def releases do
    [
      example_cli_app: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64],
            linux: [os: :linux, cpu: :x86_64],
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end
end
