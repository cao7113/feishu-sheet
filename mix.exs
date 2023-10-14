defmodule FeishuSheet.MixProject do
  use Mix.Project

  def project do
    [
      app: :feishu_sheet,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Hex pkg
      description: "Utils to operate Feishu Sheets.",
      package: package()
    ]
  end

  defp package() do
    [
      name: "feishu_sheet",
      links: %{
        "GitHub" => "https://github.com/cao7113/feishu-sheet"
      },
      source_url: "https://github.com/cao7113/feishu-sheet",
      home_url: "https://github.com/cao7113/feishu-sheet",
      # files:
      #   ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE* license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
      # mod: {FeishuSheet.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:req, "~> 0.3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
