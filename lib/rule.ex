defmodule RuleEngineWithDocs.Rule do

# Rule Attributes
# `id`: A unique id to identify the `Rule`. This is the string following `defrule`. An error is raised when two rules in a `Ruleset` are defined with the same id or `id` is set to `nil`.
# `name`: A short name to label the rule.
# `description`: Describes the rule in more detail. This can be a one-line or multi-line string.
# `type`: Assigns a type to the rule. Using a type like `:error` or `:notice` can be useful for building validation rules and generating messages. The default value is `:undefined`.
# `condition`: This is the code that is evaluated for the rule. The `data` Map is passed into each rule and functions can be called from the code. The code should return `true` or `false`. An error is raised when a rule is defined with `condition`=`nil`.
# `message`: A message can be specified in a rule and will be returned if the `condition` evaluates as `true`. This can be a plain string but string interpolation is applied.
# `fields`: It is recommended to list all fields referenced in the `condition`. Fields can be helpful for both the documentation and gathering metrics about what rules are triggered. The first field is considered the primary field and used when a message is returned. If a message is returned and no fields are defined, `:base` is used as the primary field.
# `tags`: Tags can be helpful for both the documentation and gathering metrics about what rules are triggered. These can be used to set categories and other labels to classify rules.
# `if`: This code defines the requirement or scenario for the rule to apply. The `data` Map is passed into each rule and functions can be called from the code. The code should return `true` or `false`. This defaults to `true` which means the rule will be evaluated when a `Ruleset` is run.

  defstruct [
    id: nil,
    type: nil,
    description: nil,
    fields: [],
    condition: nil,
    if: true,
    name: nil,
    message: nil,
    tags: []
  ]

end
