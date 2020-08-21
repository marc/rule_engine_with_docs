# rule_engine_with_docs

## Overview
rule_engine_with_docs is an Elixir library that can be used to define rules, their descriptions and other attributes. The rules can be used to code validation logic and other business rules.

A rule set runs against the specified data and returns a data structure containing the results of all evaluated rules and any generated messages.

The rule engine can generate documentation directly from the rule definitions. This helps prevent documentation mistakes and avoids manually keeping up with documentation when rule code is changed.


## Adding rule_engine_with_docs to Your Project

Add `rule_engine_with_docs` as a dependency to your project's `mix.exs`:
```elixir
defp deps do
  [
    {:rule_engine_with_docs, github: "marc/rule_engine_with_docs"}
  ]
end
```

See the next section for some sample validation rules to get started.


## Getting Started with Rule Definitions

`Rule`s are defined in a `Ruleset`.

These sample validation rules could be applied to data submitted through an api, batch file, web form, etc.

```elixir
defmodule SampleValidationRuleset do
  use RuleEngineWithDocs.Ruleset

  defrule "simple_rule01",
    description: "A simple rule example.",
    condition: 1 < 10

  defrule "test_data_detector",
    name: "No Test Data Allowed",
    description: "Do not allow the word 'test' (case insensitive) in the first name, last name or guardian name.",
    type: :error,
    fields: [:first_name, :guardian_name, :last_name],
    tags: [:test_data],
    condition: Regex.match?(~r/test/i, "#{data[:registration][:first_name]}") ||
      Regex.match?(~r/test/i, "#{data[:registration][:last_name]}") ||
      Regex.match?(~r/test/i, "#{data[:registration][:guardian_name]}"),
    message: "Test data detected in one of the following fields: first_name, guardian_name, last_name."

  defrule "age_check_18",
    name: "Age Check 18+",
    description: """
    If a date of birth is submitted, check if the person is 18+ as of today.

    * This rule does not apply if no valid **ISO 8601** date (YYYY-MM-DD) was submitted.
    * Using `Date.diff` to check the number of days between the date of birth and today.
    * Using _markdown_ in the description!
    """,
    type: :notice,
    message: "This person is a minor based on today's date and the submitted date of birth (#{data[:registration][:date_of_birth]}).",
    fields: [:date_of_birth],
    tags: [:single_field],
    condition: Date.diff(Date.utc_today, Date.from_iso8601!("#{data[:registration][:date_of_birth]}")) < (18*365),
    if: :ok == List.first(Tuple.to_list(Date.from_iso8601("#{data[:registration][:date_of_birth]}")))

  defrule "guardian_for_minor",
    name: "Guardian Name Required for Minors",
    description: """
    If a date of birth is submitted in ISO 8601 format (YYYY-MM-DD), check if the person is 18+ as of today to determine if they are a minor.
    The guardian name is required if the registration is submitted for a minor.
    """,
    message: "The guardian name is required if the registration is submitted for a minor.",
    type: :error,
    fields: [:guardian_name, :date_of_birth],
    tags: [:correlation, :missing_data],
    condition: String.length(String.trim("#{data[:registration][:guardian_name]}")) == 0,
    if: :ok == List.first(Tuple.to_list(Date.from_iso8601("#{data[:registration][:date_of_birth]}"))) &&
      Date.diff(Date.utc_today, Date.from_iso8601!("#{data[:registration][:date_of_birth]}")) < (18*365)

  defrule "contact_info_req",
    name: "No Contact Information Provided",
    type: :error,
    fields: [:email, :phone],
    tags: [:contact_info, :missing_data],
    condition: (String.length(String.trim("#{data[:registration][:email]}")) == 0) &&
      (String.length(String.trim("#{data[:registration][:phone]}")) == 0),
    message: "No contact information provided. One of the following contact information fields is required: email, phone"

  defrule "first_name_length_fl",
    name: "Maximum First Name Length (FL)",
    description: """
    This sample rule is only active in Florida.
    The first name has a maximum length of 100 characters.
    """,
    type: :notice,
    fields: [:first_name],
    tags: [:maximum_length, :single_field, :florida],
    condition: String.length(data[:registration][:first_name]) > 100,
    message: "First name should be at most #{50+50} characters in length in Florida.",
    if: data[:registration][:state] == "FL"

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

`if`: This code defines the requirement or scenario for the rule to apply. The `data` Map is passed into each rule and functions can be called from the code. The code should return `true` or `false`. This defaults to `true` which means the rule will be evaluated when a `Ruleset` is run. A rule can be deactivated by setting this to `false`.


## Running a Ruleset and Evaluating Rules

After defining some `Rule`s in a `Ruleset`, the rules can be evaluated:

```elixir
data = %{
  registration: %{
    first_name: "Test",
    date_of_birth: "1984-01-01"
  }
}
# %{registration: %{date_of_birth: "1984-01-01", first_name: "Test"}}

SampleValidationRuleset.run(data)
# %{
#   condition_results: %{
#     "age_check_18" => false,
#     "contact_info_req" => true,
#     "simple_rule01" => true,
#     "test_data_detector" => true
#   },
#   fields: %{email: 1, first_name: 1, guardian_name: 1, last_name: 1, phone: 1},
#   if_results: %{
#     "age_check_18" => true,
#     "contact_info_req" => true,
#     "first_name_length_fl" => false,
#     "guardian_for_minor" => false,
#     "simple_rule01" => true,
#     "test_data_detector" => true
#   },
#   messages: %{
#     error: %{
#       email: ["No contact information provided. One of the following contact information fields is required: email, phone"],
#       first_name: ["Test data detected in one of the following fields: first_name, guardian_name, last_name."]
#     }
#   },
#   tags: %{contact_info: 1, missing_data: 1, test_data: 1},
#   types: %{
#     error: ["contact_info_req", "test_data_detector"],
#     undefined: ["simple_rule01"]
#   }
# }


data = %{
  registration: %{
    first_name: "Sample__10________20________30________40________50________60________70________80________90_______100-over 100 characters",
    last_name: "Name",
    date_of_birth: "2525-01-01",
    email: "test@test.test"
  }
}
# %{
#   registration: %{
#     date_of_birth: "2037-01-01",
#     email: "test@test.test",
#     first_name: "Sample__10________20________30________40________50________60________70________80________90_______100-over 100 characters",
#     last_name: "Name"
#   }
# }

SampleValidationRuleset.run(data)
# %{
#   condition_results: %{
#     "age_check_18" => true,
#     "contact_info_req" => false,
#     "guardian_for_minor" => true,
#     "simple_rule01" => true,
#     "test_data_detector" => false
#   },
#   fields: %{date_of_birth: 2, guardian_name: 1},
#   if_results: %{
#     "age_check_18" => true,
#     "contact_info_req" => true,
#     "first_name_length_fl" => false,
#     "guardian_for_minor" => true,
#     "simple_rule01" => true,
#     "test_data_detector" => true
#   },
#   messages: %{ 
#     error: %{
#       guardian_name: ["The guardian name is required if the registration is submitted for a minor."]
#     },
#     notice: %{
#       date_of_birth: ["This person is a minor based on today's date and the submitted date of birth # (2525-01-01)."]
#     }
#   },
#   tags: %{correlation: 1, missing_data: 1, single_field: 1},
#   types: %{
#     error: ["guardian_for_minor"],
#     notice: ["age_check_18"],
#     undefined: ["simple_rule01"]
#   }
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

Markdown documentation is returned as a String by `SampleValidationRuleset.markdown_doc`.
To see the markdown generated for the `SampleValidationRuleset`, see the [SampleValidationRuleset.md](SampleValidationRuleset.md) file.

The following documentation structure is returned for `SampleValidationRuleset.doc_struct`:
```elixir
%{
  all_fields: %{
    date_of_birth: ["age_check_18", "guardian_for_minor"],
    email: ["contact_info_req"],
    first_name: ["first_name_length_fl", "test_data_detector"],
    guardian_name: ["guardian_for_minor", "test_data_detector"],
    last_name: ["test_data_detector"],
    phone: ["contact_info_req"]
  },
  all_tags: %{
    contact_info: ["contact_info_req"],
    correlation: ["guardian_for_minor"],
    florida: ["first_name_length_fl"],
    maximum_length: ["first_name_length_fl"],
    missing_data: ["contact_info_req", "guardian_for_minor"],
    single_field: ["age_check_18", "first_name_length_fl"],
    test_data: ["test_data_detector"]
  },
  all_types: %{
    error: ["contact_info_req", "guardian_for_minor", "test_data_detector"],
    notice: ["age_check_18", "first_name_length_fl"],
    undefined: ["simple_rule01"]
  },
  rule_ids: ["age_check_18", "contact_info_req", "first_name_length_fl",
   "guardian_for_minor", "simple_rule01", "test_data_detector"]
}
```

`Ruleset.rule/1` returns all attributes of a rule, including the condition code and if code.
```elixir
SampleValidationRuleset.rule("simple_rule01").description
# "A simple rule example."
SampleValidationRuleset.rule("contact_info_req").name    
# "No Contact Information Provided"
SampleValidationRuleset.rule("contact_info_req").message
# "No contact information provided. One of the following contact information fields is required: email, phone"
SampleValidationRuleset.rule("simple_rule01") 
# %RuleEngineWithDocs.Rule{
#   condition: {:<, [line: 6], [1, 10]},
#   description: "A simple rule example.",
#   fields: [],
#   id: "simple_rule01",
#   if: true,
#   message: nil,
#   name: nil,
#   tags: [],
#   type: :undefined
# }
```
Notice that the `condition` code and `if` code is Elixir code as returned by `Macro.escape/1`.
To show a text representation of the `condition` code or `if` code, use `Macro.to_string/1`:

```elixir
Macro.to_string(SampleValidationRuleset.rule("age_check_18").condition)
# "Date.diff(Date.utc_today(), Date.from_iso8601!(\"\#{data[:registration][:date_of_birth]}\")) < 18 * 365"
Macro.to_string(SampleValidationRuleset.rule("contact_info_req").condition)
# "String.length(String.trim(\"\#{data[:registration][:email]}\")) == 0 && String.length(String.trim(\"\#{data[:registration][:phone]}\")) == 0"
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
%{id: id, if_result: if_result, condition_result: condition_result, message: message} = SampleValidationRuleset.eval_rule(data, "contact_info_req")
# %{
#   condition_result: true,
#   id: "contact_info_req",
#   if_result: true,
#   message: "No contact information provided. One of the following contact information fields is required: email, phone"
# }
data = %{registration: %{email: "test@test.test"}}
# %{registration: %{email: "test@test.test"}}
%{id: id, if_result: if_result, condition_result: condition_result, message: message} = SampleValidationRuleset.eval_rule(data, "contact_info_req")
# %{
#   condition_result: false,
#   id: "contact_info_req",
#   if_result: true,
#   message: nil
# }
```

Since we are only testing a single rule, we do not need to create `data` with all attributes, only the fields relevant to this rule.