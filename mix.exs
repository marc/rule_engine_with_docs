defmodule RuleEngineWithDocs.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rule_engine_with_docs,
      version: "0.2.0",
      elixir: ">= 1.9.1",
      docs: [
        main: "rule_engine_with_docs",
        source_url: "https://github.com/marc/rule_engine_with_docs",
        source_ref: "master"
      ],
      description: description(),
      package: package(),
      deps: []
    ]
  end

  def application do
    [applications: []]
  end

  defp package do
    [
      contributors: ["Marc Bellingrath"],
      licenses: [""],
      links: %{ "Source"=>"https://github.com/marc/rule_engine_with_docs"}
    ]
  end

  defp description do
    """
    rule_engine_with_docs is an Elixir library that can be used to define rules, their descriptions and other attributes. The rules can be used to code validation logic and other business rules.

    A rule set runs against the specified data and returns a data structure containing the results of all evaluated rules and any generated messages.
    
    The rule engine can generate documentation directly from the rule definitions. This helps prevent documentation mistakes and avoids manually keeping up with documentation when rule code is changed.
    """
  end
end
