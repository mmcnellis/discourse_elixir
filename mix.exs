defmodule DiscourseElixir.Mixfile do
  use Mix.Project

  def project do
    [app: :discourse_elixir,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "A Discourse client for Elixir",
     package: package,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:httpoison, :poison]]
  end

  def package do
    [
      maintainers: ["Molloy McNellis"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/mmcnellis/discourse_elixir"}
    ]
  end
  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.10.0"},
     {:poison, "~> 3.0"}]
  end
end
