defmodule RuleEngineWithDocs.Ruleset do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import RuleEngineWithDocs.Ruleset

      # Initialize @rules to an empty List
      @rules []

      # Invoke Ruleset.__before_compile__/1 before the module is compiled
      @before_compile RuleEngineWithDocs.Ruleset
    end
  end

  @doc """
  Defines a rule with the given id.

  ## Examples (also see test/ruleset_test.exs)

  defmodule SampleRuleset do
    use RuleEngineWithDocs.Ruleset

    defrule "simple_rule01",
      description: "A simple rule example.",
      condition: 1 < 10

    defrule "rule02",
      name: "Minimum Name Length (Florida)",
      description: \"\"\"
      the second rule
      ---------------
      This rule is only active in Florida.
      The Sample 1 name has a minimum length.
      \"\"\",
      type: :error,
      fields: [:name],
      tags: [:minimum_length, :single_field, :florida],
      condition: String.length(data[:sample1][:name]) < 4,
      message: "Sample 1 name must be at least #{2+2} characters in length.",
      if: data[:sample1][:state] == "FL"

    defrule "contact_info1",
      name: "Contact Information Required",
      type: :error,
      fields: [:email, :phone, :team_chat_user_name],
      tags: [:contact_info],
      condition: (String.length(String.trim("\#{data[:sample1][:email]}")) == 0) &&
        (String.length(String.trim("\#{data[:sample1][:phone]}")) == 0) &&
        (String.length(String.trim("\#{data[:sample1][:team_chat_user_name]}")) == 0),
      message: "Contact information required. Provide at least one of: email, phone, team_chat_user_name",
      if: true
  end

  """
  defmacro defrule(id, kv) do
    condition = Keyword.get(kv, :condition, nil)
    if is_nil(condition) do
      raise "Attempting to define rule id #{id} with condition=nil!"
    end
    if is_nil(id) do
      raise "Attempting to define a rule with id=nil! Look for the following rule definition: #{inspect kv}"
    end
    message = Keyword.get(kv, :message, nil)
    run_if = Keyword.get(kv, :if, true)
    description = Keyword.get(kv, :description, nil)
    type = Keyword.get(kv, :type, :undefined)
    name = Keyword.get(kv, :name, nil)
    fields = Keyword.get(kv, :fields, [])
    tags = Keyword.get(kv, :tags, [])

    # IO.inspect "----------------------"
    # condition_str = Macro.to_string(condition)
    # message_str = Macro.to_string(message)
    # run_if_str = Macro.to_string(run_if)
    # IO.inspect %{
    #   id: id,
    #   type: type,
    #   description: description,
    #   fields: fields,
    #   condition: condition_str,
    #   message: message_str,
    #   if: run_if_str
    # }
    # IO.inspect "---------------------"

    quote do

      if Enum.member?(@rules, unquote(id)) do
        raise "Rule id #{unquote(id)} has already been defined for this Ruleset!"
      end
      # Prepend the newly defined rule to the list of rules
      @rules [unquote(id) | @rules]

      # Process the rule with `eval_rule("rule01")`:
      # 1. Evaluate the `if` condition and only proceed if it returns true.
      # 2. Evaluate the `condition`
      # 3. If `condition` returns true, evaluate the `message`
      # 4. Return the id, `if` result, `condition` result and evaluated `message` (or nil)
      def eval_rule(data, unquote(id)) do
        if_result = condition_result = message_result = nil
        {if_result,_data} = Code.eval_quoted unquote(Macro.escape(run_if)), [data: data], __ENV__

        {condition_result,_data} = cond do
          if_result ->
            Code.eval_quoted unquote(Macro.escape(condition)), [data: data], __ENV__
          true ->
            {nil,nil}
        end

        {message_result, _data} = cond do
          condition_result && !is_nil(unquote(Macro.escape(message))) ->
            Code.eval_quoted unquote(Macro.escape(message)), [data: data], __ENV__ 
          true ->
            {nil, nil}
        end

        %{id: unquote(id), if_result: if_result, condition_result: condition_result, message: message_result}
      end

      # Return a struct of the defined rule with `rule("rule01")`.
      def rule(unquote(id)) do
        %RuleEngineWithDocs.Rule{
          id: unquote(id),
          type: unquote(type),
          description: unquote(description),
          fields: unquote(fields),
          condition: unquote(Macro.escape(condition)),
          name: unquote(name),
          message: unquote(Macro.escape(message)),
          if: unquote(Macro.escape(run_if)),
          tags: unquote(tags)
        }
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do

      # Evaluate all rules and return detailed results:
      #
      # Sample result:
      # %{
      #   condition_results: %{
      #     "email001" => true,
      #     "email002" => true,
      #     "rule02" => true,
      #     "rule03" => false,
      #     "simple_rule1" => true
      #   },
      #   fields: %{email: 2, name: 1},
      #   if_results: %{
      #     "email001" => true,
      #     "email002" => true,
      #     "not_active1" => false,
      #     "rule02" => true,
      #     "rule03" => true,
      #     "simple_rule1" => true
      #   },
      #   messages: %{
      #     error: %{
      #       email: ["Sample 1 email cannot be blank."],
      #       name: ["Sample 1 name must be at least 4 characters in length."]
      #     },
      #     notice: %{email: ["Sample 1 email format is invalid."]}
      #   },
      #   tags: %{
      #     invalid_format: 1,
      #     minimum_length: 1,
      #     missing_field: 1,
      #     single_field: 1
      #   },
      #   types: %{error: ["email001", "rule02", "simple_rule1"], notice: ["email002"]}
      # }
      def run(data) do
        {:ok, condition_results} = RuleEngineWithDocs.ResultsMap.start_link(%{})
        {:ok, if_results} = RuleEngineWithDocs.ResultsMap.start_link(%{})
        {:ok, fields_results} = RuleEngineWithDocs.ResultsMap.start_link(%{})
        {:ok, tags_results} = RuleEngineWithDocs.ResultsMap.start_link(%{})
        {:ok, type_results} = RuleEngineWithDocs.ResultsMapOfLists.start_link(%{})
        {:ok, messages} = RuleEngineWithDocs.ResultsList.start_link([])

        # TODO Evaluate rules in parallel?
        Enum.each @rules, fn id ->
          rule_def = rule(id)
          primary_field = List.first(rule_def.fields)
          %{id: _id, if_result: if_result, condition_result: condition_result, message: message} = apply(__MODULE__, :eval_rule, [data, id])
          # IO.puts "Rule: #{id}(data), if_result=#{if_result},condition_result=#{condition_result}, message=#{message}, primary_field=#{primary_field}"
          RuleEngineWithDocs.ResultsMap.put(if_results, id, if_result)
          if if_result do
            RuleEngineWithDocs.ResultsMap.put(condition_results, id, condition_result)
          end
          if condition_result do
            RuleEngineWithDocs.ResultsMapOfLists.add(type_results, rule_def.type, id)
            rule_def.fields
            |> Enum.each(fn(field) ->
              RuleEngineWithDocs.ResultsMap.inc(fields_results, field)
            end)
            rule_def.tags
            |> Enum.each(fn(tag) ->
              RuleEngineWithDocs.ResultsMap.inc(tags_results, tag)
            end)
            if !is_nil(message) && !is_nil(rule_def.type) do
              RuleEngineWithDocs.ResultsList.append(messages, {rule_def.type, primary_field || :base, message})
            end
          end
        end
        %{
          condition_results: RuleEngineWithDocs.ResultsMap.get_map(condition_results),
          if_results: RuleEngineWithDocs.ResultsMap.get_map(if_results),
          messages: RuleEngineWithDocs.ResultsList.get_messages_map(messages),
          fields: RuleEngineWithDocs.ResultsMap.get_map(fields_results),
          tags: RuleEngineWithDocs.ResultsMap.get_map(tags_results),
          types: RuleEngineWithDocs.ResultsMapOfLists.get_map(type_results)
        }
      end

      # Returns a Map of the documentation based on the rule definitions.
      #
      # This is used to generate the markdown document with `markdown_doc/0` and
      # can also be used to generate custom documentation formats like html or pdf.
      #
      # Sample results:
      # %{
      #   all_fields: %{
      #     email: ["email001", "email002", "not_active1"],
      #     name: ["rule02", "rule03"]
      #   },
      #   all_tags: %{
      #     invalid_format: ["email002"],
      #     maximum_length: ["rule03"],
      #     minimum_length: ["rule02"],
      #     missing_field: ["email001"],
      #     single_field: ["rule02", "rule03"]
      #   },
      #   all_types: %{
      #     error: ["email001", "not_active1", "rule02", "rule03", "simple_rule1"],
      #     notice: ["email002"]
      #   },
      #   rule_ids: ["email001", "email002", "not_active1", "rule02", "rule03",
      #    "simple_rule1"]
      # }
      def doc_struct() do
        {:ok, fields} = RuleEngineWithDocs.ResultsList.start_link([])
        {:ok, tags} = RuleEngineWithDocs.ResultsList.start_link([])
        {:ok, types} = RuleEngineWithDocs.ResultsList.start_link([])
        all_rule_ids = Enum.sort(@rules)
        ruleset_info = %{
          all_fields: [],
          all_tags: [],
          all_types: []
        }
        @rules
        |> Enum.reduce(ruleset_info, fn rule_id, acc ->
          rule_def = rule(rule_id)
          Enum.each(rule_def.fields, fn field -> RuleEngineWithDocs.ResultsList.prepend(fields, {field, rule_id}) end)
          Enum.each(rule_def.tags, fn tag -> RuleEngineWithDocs.ResultsList.prepend(tags, {tag, rule_id}) end)
          RuleEngineWithDocs.ResultsList.prepend(types, {rule_def.type, rule_id})
        end)
        all_fields = Map.new(RuleEngineWithDocs.ResultsList.get_list(fields), fn {field,_rule_id} -> {field, []} end)
        all_fields = Enum.reduce(RuleEngineWithDocs.ResultsList.get_list(fields),all_fields, fn {field,rule_id}, acc ->
          update_in acc[field], &(Enum.sort([rule_id | &1]))
        end)
        all_tags = Map.new(RuleEngineWithDocs.ResultsList.get_list(tags), fn {tag,_rule_id} -> {tag, []} end)
        all_tags = Enum.reduce(RuleEngineWithDocs.ResultsList.get_list(tags),all_tags, fn {tag,rule_id}, acc ->
          update_in acc[tag], &(Enum.sort([rule_id | &1]))
        end)
        all_types = Map.new(RuleEngineWithDocs.ResultsList.get_list(types), fn {type,_rule_id} -> {type, []} end)
        all_types = Enum.reduce(RuleEngineWithDocs.ResultsList.get_list(types),all_types, fn {type,rule_id}, acc ->
          update_in acc[type], &(Enum.sort([rule_id | &1]))
        end)
        %{
          rule_ids: all_rule_ids,
          all_fields: all_fields,
          all_tags: all_tags,
          all_types: all_types
        }
      end

      # Basic markdown documentation based on the rule definitions.
      # See `test/ruleset_test.exs` or `SampleValidationRuleset.md` for sample output.
      def markdown_doc() do
        docstruct = apply(__MODULE__, :doc_struct, [])
        """
        # Ruleset Documentation

        ## Rules
        #{md_all_rules(docstruct[:rule_ids])}

        ## Fields
        #{md_map_of_lists(docstruct[:all_fields])}

        ## Tags
        #{md_map_of_lists(docstruct[:all_tags])}

        ## Types
        #{md_map_of_lists(docstruct[:all_types])}

        ## Rule Descriptions
        #{md_rule_details(docstruct[:rule_ids])}
        """
      end

      defp md_all_rules(all_rule_ids) do
        all_rule_ids
        |> Enum.map(fn rule_id ->
          rule_def = rule(rule_id)
          "#{rule_id} - #{rule_def.name}\n\n"    
        end)
      end

      defp md_rule_details(all_rule_ids) do
        all_rule_ids
        |> Enum.map(fn rule_id ->
          rule_def = rule(rule_id)
          """
          ### #{rule_id}
          Name: #{rule_def.name}

          Type: #{rule_def.type}
          
          Fields: #{Enum.join(rule_def.fields, ", ")}

          Tags: #{Enum.join(rule_def.tags, ", ")}

          Message: #{Macro.to_string(rule_def.message)}

          #### Description
          #{rule_def.description}

          """    
        end)
      end

      defp md_map_of_lists(map) do
        map
        |> Enum.map(fn {key,val} ->
          """
          ### #{key}
          #{Enum.map(val, fn rule_id -> "#{rule_id}\n\n" end)}
          """
        end)
      end
    end
  end
end
