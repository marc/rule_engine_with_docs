defmodule RulesetTest do

  defmodule SampleRuleset do
    use RuleEngineWithDocs.Ruleset
  
    defrule "simple_rule1",
      condition: 1 < 2

    defrule "name_length_min",
      name: "Minimum Name Length",
      description: """
      Descriptions can contain a block of text.
      ...
      ...
      ...
      The Sample 1 name has a minimum length.
      """,
      type: :error,
      fields: [:name],
      tags: [:minimum_length, :single_field],
      condition: String.length(data[:sample1][:name]) < 5,
      message: "Sample 1 name must be at least 5 characters in length.",
      if: true

    defrule "name_length_max",
      name: "Maximum Name Length",
      description: "The Sample 1 name has a maximum length.",
      type: :error,
      fields: [:name],
      tags: [:maximum_length, :single_field],
      condition: String.length(data[:sample1][:name]) > 40,
      message: "Sample 1 name cannot be longer than 40 characters in length."

    defrule "name_cannot_be_name",
      name: "Invalid Name",
      type: :error,
      fields: [:name],
      tags: [:value_not_allowed],
      condition: data[:sample1][:name] == "Name",
      message: "Sample 1 name cannot be '#{data[:sample1][:name]}'."

    defrule "not_active1",
      name: "Deactivated Rule",
      fields: [:email],
      condition: true,
      if: false

    defrule "email001",
      name: "Sample 1 Email Required",
      message: "Sample 1 email cannot be blank.",
      fields: [:email],
      type: :error,
      tags: [:empty],
      condition: String.length("#{data[:sample1][:email]}") == 0

    defrule "email002",
      name: "Sample 1 Email Format",
      message: "Sample 1 email format is invalid.",
      type: :notice,
      fields: [:email],
      tags: [:invalid_format],
      condition: Regex.match?(~r/(.*?)\@(.*?)\.(.*?)/, "#{data[:sample1][:email]}")

    defrule "contact_info_fl",
      name: "Contact Information Required (FL)",
      type: :error,
      fields: [:email, :phone, :team_chat_user_name],
      tags: [:contact_info, :florida],
      condition: (String.length(String.trim("#{data[:sample1][:email]}")) == 0) &&
        (String.length(String.trim("#{data[:sample1][:phone]}")) == 0) &&
        (String.length(String.trim("#{data[:sample1][:team_chat_user_name]}")) == 0),
      message: "Contact information required for users in Florida. Provide at least one of: email, phone, team_chat_user_name",
      if: data[:sample1][:state] == "FL"

    defrule "two_data_fields",
      name: "Compare 2 data fields",
      description: "Compare two fields from the specified data.",
      type: :notice,
      fields: [:amount],
      tags: [:amount, :correlation],
      condition: data[:sample1][:amount] > data[:sample2][:amount]

    defrule "approved_snack",
      name: "Approved Snacks",
      description: "Only allow approved snacks when the snack police is active.",
      type: :warning,
      message: "Unauthorized snack detected! Only the following snacks are allowed: fruit, granola, ice cream",
      condition: Enum.member?(["fruit", "granola", "ice cream"], data[:snack]),
      if: data[:snack_police_active] == true
    
  end

  use ExUnit.Case

  describe "defrule/2" do
    test "define a basic rule in a Ruleset" do
      assert 2 == 1+1
      rule = SampleRuleset.rule("simple_rule1")
      assert "simple_rule1" == rule.id
    end

    test "define a rule that checks input data" do
      data = %{
        sample1: %{
          name: "Testing"
        }
      }
      %{id: _id, if_result: if_result, condition_result: condition_result, message: message} = SampleRuleset.eval_rule(data, "name_length_min")
      assert if_result == true
      assert condition_result == false
      assert message == nil
    
      data = %{
        sample1: %{
          name: "aaa"
        }
      }
      %{id: _id, if_result: if_result, condition_result: condition_result, message: message} = SampleRuleset.eval_rule(data, "name_length_min")
      assert if_result == true
      assert condition_result == true
      assert message == "Sample 1 name must be at least 5 characters in length."
    end
  end

  describe "run/1" do
    test "run all rules" do
      data = %{
        sample1: %{
          name: "Name"
        }
      }
      expected_output = %{
        condition_results: %{
          "email001" => true,
          "email002" => false,
          "name_cannot_be_name" => true,
          "name_length_max" => false,
          "name_length_min" => true,
          "simple_rule1" => true,
          "two_data_fields" => false
        },
        fields: %{email: 1, name: 2},
        if_results: %{
          "approved_snack" => false,
          "contact_info_fl" => false,
          "email001" => true,
          "email002" => true,
          "name_cannot_be_name" => true,
          "name_length_max" => true,
          "name_length_min" => true,
          "not_active1" => false,
          "simple_rule1" => true,
          "two_data_fields" => true
        },
        messages: %{
          error: %{
            email: ["Sample 1 email cannot be blank."],
            name: ["Sample 1 name cannot be 'Name'.",
             "Sample 1 name must be at least 5 characters in length."]
          }
        },
        tags: %{empty: 1, minimum_length: 1, single_field: 1, value_not_allowed: 1},
        types: %{
          error: ["email001", "name_cannot_be_name", "name_length_min"],
          undefined: ["simple_rule1"]
        }
      }      

      run_result = SampleRuleset.run(data)
         
      # IO.inspect run_result
      assert run_result == expected_output
    end
  end

  describe "doc_struct/0" do
    test "generate documentation structure" do
      expected_doc_struct = %{
        all_fields: %{
          amount: ["two_data_fields"],
          email: ["contact_info_fl", "email001", "email002", "not_active1"],
          name: ["name_cannot_be_name", "name_length_max", "name_length_min"],
          phone: ["contact_info_fl"],
          team_chat_user_name: ["contact_info_fl"]
        },
        all_tags: %{
          amount: ["two_data_fields"],
          contact_info: ["contact_info_fl"],
          correlation: ["two_data_fields"],
          empty: ["email001"],
          florida: ["contact_info_fl"],
          invalid_format: ["email002"],
          maximum_length: ["name_length_max"],
          minimum_length: ["name_length_min"],
          single_field: ["name_length_max", "name_length_min"],
          value_not_allowed: ["name_cannot_be_name"]
        },
        all_types: %{
          error: ["contact_info_fl", "email001", "name_cannot_be_name",
           "name_length_max", "name_length_min"],
          notice: ["email002", "two_data_fields"],
          undefined: ["not_active1", "simple_rule1"],
          warning: ["approved_snack"]
        },
        rule_ids: ["approved_snack", "contact_info_fl", "email001", "email002",
         "name_cannot_be_name", "name_length_max", "name_length_min", "not_active1",
         "simple_rule1", "two_data_fields"]
      }

      doc_struct = SampleRuleset.doc_struct
      
      # IO.inspect doc_struct
      assert doc_struct == expected_doc_struct
    end
  end

  describe "markdown_doc/0" do
    test "generate markdown documentation" do
      markdown = SampleRuleset.markdown_doc()
      
      expected_markdown = """
      # Ruleset Documentation

      ## Rules
      approved_snack - Approved Snacks
      
      contact_info_fl - Contact Information Required (FL)
      
      email001 - Sample 1 Email Required
      
      email002 - Sample 1 Email Format
      
      name_cannot_be_name - Invalid Name
      
      name_length_max - Maximum Name Length
      
      name_length_min - Minimum Name Length
      
      not_active1 - Deactivated Rule
      
      simple_rule1 - 
      
      two_data_fields - Compare 2 data fields
      
      
      
      ## Fields
      ### amount
      two_data_fields
      
      
      ### email
      contact_info_fl
      
      email001
      
      email002
      
      not_active1
      
      
      ### name
      name_cannot_be_name
      
      name_length_max
      
      name_length_min
      
      
      ### phone
      contact_info_fl
      
      
      ### team_chat_user_name
      contact_info_fl
      
      
      
      
      ## Tags
      ### amount
      two_data_fields
      
      
      ### contact_info
      contact_info_fl
      
      
      ### correlation
      two_data_fields
      
      
      ### empty
      email001
      
      
      ### florida
      contact_info_fl
      
      
      ### invalid_format
      email002
      
      
      ### maximum_length
      name_length_max
      
      
      ### minimum_length
      name_length_min
      
      
      ### single_field
      name_length_max
      
      name_length_min
      
      
      ### value_not_allowed
      name_cannot_be_name
      
      
      
      
      ## Types
      ### error
      contact_info_fl
      
      email001
      
      name_cannot_be_name
      
      name_length_max
      
      name_length_min
      
      
      ### notice
      email002
      
      two_data_fields
      
      
      ### undefined
      not_active1
      
      simple_rule1
      
      
      ### warning
      approved_snack
      
      
      
      
      ## Rule Descriptions
      ### approved_snack
      Name: Approved Snacks
      
      Type: warning
      
      Fields: 
      
      Tags: 
      
      Message: "Unauthorized snack detected! Only the following snacks are allowed: fruit, granola, ice cream"
      
      #### Description
      Only allow approved snacks when the snack police is active.
      
      ### contact_info_fl
      Name: Contact Information Required (FL)
      
      Type: error
      
      Fields: email, phone, team_chat_user_name
      
      Tags: contact_info, florida
      
      Message: "Contact information required for users in Florida. Provide at least one of: email, phone, team_chat_user_name"
      
      #### Description
      
      
      ### email001
      Name: Sample 1 Email Required
      
      Type: error
      
      Fields: email
      
      Tags: empty
      
      Message: "Sample 1 email cannot be blank."
      
      #### Description
      
      
      ### email002
      Name: Sample 1 Email Format
      
      Type: notice
      
      Fields: email
      
      Tags: invalid_format
      
      Message: "Sample 1 email format is invalid."
      
      #### Description
      
      
      ### name_cannot_be_name
      Name: Invalid Name
      
      Type: error
      
      Fields: name
      
      Tags: value_not_allowed
      
      Message: "Sample 1 name cannot be '\#{data[:sample1][:name]}'."
      
      #### Description
      
      
      ### name_length_max
      Name: Maximum Name Length
      
      Type: error
      
      Fields: name
      
      Tags: maximum_length, single_field
      
      Message: "Sample 1 name cannot be longer than 40 characters in length."
      
      #### Description
      The Sample 1 name has a maximum length.
      
      ### name_length_min
      Name: Minimum Name Length
      
      Type: error
      
      Fields: name
      
      Tags: minimum_length, single_field
      
      Message: "Sample 1 name must be at least 5 characters in length."
      
      #### Description
      Descriptions can contain a block of text.
      ...
      ...
      ...
      The Sample 1 name has a minimum length.
      
      
      ### not_active1
      Name: Deactivated Rule
      
      Type: undefined
      
      Fields: email
      
      Tags: 
      
      Message: nil
      
      #### Description
      
      
      ### simple_rule1
      Name: 
      
      Type: undefined
      
      Fields: 
      
      Tags: 
      
      Message: nil
      
      #### Description
      
      
      ### two_data_fields
      Name: Compare 2 data fields
      
      Type: notice
      
      Fields: amount
      
      Tags: amount, correlation
      
      Message: nil
      
      #### Description
      Compare two fields from the specified data.
      
      
      """

      # IO.puts markdown
      assert markdown == expected_markdown
    end
  end


end