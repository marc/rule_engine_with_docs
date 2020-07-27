# rule_engine_with_docs

## Overview
rule_engine_with_docs is an Elixir library that can be used to define rules, their descriptions and other attributes. The rules can be used to code validation logic and other business rules.

A rule set runs against the specified data and returns a data structure containing the results of all evaluated rules and any generated messages.

The rule engine can generate documentation directly from the rule definitions. This helps prevent documentation mistakes and avoids manually keeping up with documentation when rule code is changed.


## Rule Definition

`Rule`s are defines in a `Ruleset`:

```elixir
defmodule SampleRuleset do
  use RuleEngineWithDocs.Ruleset

  defrule "simple_rule01",
    description: "A simple rule example.",
    condition: 1 < 10

  defrule "name_length_fl",
    name: "Maximum Name Length (FL)",
    description: """
    This rule is only active in Florida.
    The Sample 1 name has a maximum length of 100 characters.
    """,
    type: :error,
    fields: [:name],
    tags: [:maximum_length, :single_field, :florida],
    condition: String.length(data[:sample1][:name]) > 100,
    message: "Sample 1 name should be at most #{50+50} characters in length in Florida.",
    if: data[:sample1][:state] == "FL"

  defrule "contact_info1",
    name: "No Contact Information Provided",
    type: :notice,
    fields: [:email, :phone, :team_chat_user_name],
    tags: [:contact_info],
    condition: (String.length(String.trim("#{data[:registration][:email]}")) == 0) &&
      (String.length(String.trim("#{data[:registration][:phone]}")) == 0) &&
      (String.length(String.trim("#{data[:registration][:team_chat_user_name]}")) == 0),
    message: "No contact information provided. If you wish to receive updates, please provide at least one of the following: email, phone, team_chat_user_name"
end
```

## Rule Attributes

`id`: A unique id to identify the `Rule`. This is the string following `defrule`. An error is raised when two rules in a `Ruleset` are defined with the same id or `id` is set to `nil`.

`name`: A short name to label the rule.

`description`: Describes the rule in more detail. This can be a one-line or multi-line string.

`type`: Assigns a type to the rule. Using a type like `:error` or `:notice` can be useful for building validation rules and generating messages. The default value is `:undefined`.

`condition`: This is the code that is evaluated for the rule. The `data` Map is passed into each rule and functions can be called from the code. The code should return `true` or `false`. An error is raised when a rule is defined with `condition`=`nil`.

`message`: A message can be specified in a rule and will be returned if the `condition` evaluates as `true`. This can be a plain string but string interpolation is applied.

`fields`: It is recommended to list all fields referenced in the `condition`. Fields can be helpful for both the documentation and gathering metrics about what rules are triggered. The first field is considered the primary field and used when a message is returned. If a message is returned and no fields are defined, `:base` is used as the primary field.

`tags`: Tags can be helpful for both the documentation and gathering metrics about what rules are triggered. These can be used to set categories and other labels to classify rules.

`if`: This code defines the requirement or scenario for the rule to apply. The `data` Map is passed into each rule and functions can be called from the code. The code should return `true` or `false`. This defaults to `true` which means the rule will be evaluated when a `Ruleset` is run.


## Running a Ruleset and Evaluating Rules

After defining some `Rule`s in a `Ruleset`, the rules can be evaluated:

```elixir
data = %{
  sample1: %{
    name: "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 103"
  },
  registration: %{
  }
}
# %{
#   registration: %{},
#   sample1: %{
#     name: "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 103"
#   }
# }

SampleRuleset.run(data)
# %{
#   condition_results: %{"contact_info1" => true, "simple_rule01" => true},
#   fields: %{email: 1, phone: 1, team_chat_user_name: 1},
#   if_results: %{
#     "contact_info1" => true,
#     "name_length_fl" => false,
#     "simple_rule01" => true
#   },
#   messages: %{
#     notice: %{
#       email: ["No contact information provided. If you wish to receive updates, please provide at least one of the following: email, phone, team_chat_user_name"]
#     }
#   },
#   tags: %{contact_info: 1},
#   types: %{notice: ["contact_info1"], undefined: ["simple_rule01"]}
# }


data = %{
  sample1: %{
    name: "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 103",
    state: "FL"
  },
  registration: %{
    email: "test@test.test"
  }
}
# %{
#   registration: %{email: "test@test.test"},
#   sample1: %{
#     name: "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 103",
#     state: "FL"
#   }
# }

SampleRuleset.run(data)
# %{
#   condition_results: %{
#     "contact_info1" => false,
#     "name_length_fl" => true,
#     "simple_rule01" => true
#   },
#   fields: %{name: 1},
#   if_results: %{
#     "contact_info1" => true,
#     "name_length_fl" => true,
#     "simple_rule01" => true
#   },
#   messages: %{
#     error: %{
#       name: ["Sample 1 name should be at most 100 characters in length in Florida."]
#     }
#   },
#   tags: %{florida: 1, maximum_length: 1, single_field: 1},
#   types: %{error: ["name_length_fl"], undefined: ["simple_rule01"]}
# }
```

## A Closer Look At What is Returned by `run/1`

`condition_results`: A Map with rule ids as keys and how the rule evaluated (`true` or `false`) against the provided data. A rule's condition is only evaluated when `if` evaluates as true. This means that rule ids where `if` evaluated as false will not appear in `condition_results`.

`fields`: A Map with counters for all fields defined by rules where the `condition` evaluated as `true`. The value is a counter and can be greater than `1` if multiple rules have the same fields and their condition is met. If the counters are not wanted, use `Map.keys` for a list of fields without counters.

`if_results`: A Map with rule ids as keys and result of evaluating `if` against the provided data. This can be used to see which rules applied to the specified data.

`messages`: A Map of Maps of Lists! The first key is the `type`, the second key is the `field`. The list contains all messages for the types and fields. (A message is only returned when the `condition` evaluates as `true`.)

`tags`: A Map with counters for all tags defined by rules where the `condition` evaluated as `true`. The value is a counter and can be greater than `1` if multiple rules have the same tags and their condition is met. If the counters are not wanted, use `Map.keys` for a list of tags without counters.

`types`: A Map of Lists! A Map with keys for all the types of rules that were met. The List contains the ids of rules of that type where the `condition` evaluated as `true`. When writing validation rules, this can be used to check if any `:error` conditions were detected.


## Generating Rule Documentation

Documentation can be generated directly from the rule definitions! This helps prevent documentation mistakes and avoids manually keeping up with documentation when rule code is changed.

The library can generate a markdown document or return a Map representation of the documentation. The documentation structure can be used to build custom documentation in other formats like PDF or HTML.

Markdown documentation is returned as a String by `SampleRuleset.markdown_doc`.
To see the markdown generated for the `SampleRuleset`, see the [SampleRuleset.md](SampleRuleset.md) file.

The following documentation structure is returned for `SampleRuleset.doc_struct`:
```elixir
%{
  all_fields: %{
    email: ["contact_info1"],
    name: ["name_length_fl"],
    phone: ["contact_info1"],
    team_chat_user_name: ["contact_info1"]
  },
  all_tags: %{
    contact_info: ["contact_info1"],
    florida: ["name_length_fl"],
    maximum_length: ["name_length_fl"],
    single_field: ["name_length_fl"]
  },
  all_types: %{
    error: ["name_length_fl"],
    notice: ["contact_info1"],
    undefined: ["simple_rule01"]
  },
  rule_ids: ["contact_info1", "name_length_fl", "simple_rule01"]
}
```

All rule attributes can be retrieved with `Ruleset.rule("simple_rule01")`:
```elixir
SampleRuleset.rule("simple_rule01").description
# "A simple rule example."
```


## Additional Information

See `test/ruleset_test.exs` for some additional rule examples, run results, documentation structures and documentation output.

See `lib/ruleset.ex` for a closer look at the inner workings of a `Ruleset` and `defrule`.

Run the tests:
```
mix deps.get
mix test
```


## Testing a Rule

While `Ruleset.run/1` allows all rules to be evaluated, it can be useful to run a single rule when writing tests for a rule.

The `Ruleset.eval_rule/2` function returns the result of evaluating the `if` code against the specified data, the result of evaluating the `condition` code against the specified data (when the `if` code returns `true`) and the `message` if it is defined and the `condition` code returns `true`.

```elixir
data = %{registration: %{}}
# %{registration: %{}}
%{id: id, if_result: if_result, condition_result: condition_result, message: message} = SampleRuleset.eval_rule(data, "contact_info1")
# %{
#   condition_result: true,
#   id: "contact_info1",
#   if_result: true,
#   message: "No contact information provided. If you wish to receive updates, please provide at least one of the following: email, phone, team_chat_user_name"
# }
data = %{registration: %{email: "test@test.test"}}
# %{registration: %{email: "test@test.test"}}
%{id: id, if_result: if_result, condition_result: condition_result, message: message} = SampleRuleset.eval_rule(data, "contact_info1")
# %{condition_result: false, id: "contact_info1", if_result: true, message: nil}
```