defmodule RulesetErrorsTest do

  use ExUnit.Case

  describe "defrule/2" do
    test "raise error when defining a rule with an existing id in a Ruleset" do
      %RuntimeError{message: err} = try do
        defmodule SampleRuleset do
          use RuleEngineWithDocs.Ruleset
        
          defrule "simple_rule1",
            condition: 1 < 2
      
          defrule "simple_rule1",
            condition: 3 < 4
        end
      rescue
        e in RuntimeError -> e
      end
      assert err == "Rule id simple_rule1 has already been defined for this Ruleset!"
    end

    test "raise error when defining a rule with condition=nil" do
      %RuntimeError{message: err} = try do
        defmodule SampleRuleset do
          use RuleEngineWithDocs.Ruleset
        
          defrule "simple_rule1",
            name: "Simple Rule"
        end
      rescue
        e in RuntimeError -> e
      end
      assert err == "Attempting to define rule id simple_rule1 with condition=nil!"
    end

    test "raise error when defining a rule with id=nil" do
      %RuntimeError{message: err} = try do
        defmodule SampleRuleset do
          use RuleEngineWithDocs.Ruleset
        
          defrule nil,
            name: "Simple Rule",
            condition: 5 < 6
        end
      rescue
        e in RuntimeError -> e
      end
      assert err == "Attempting to define a rule with id=nil! Look for the following rule definition: [name: \"Simple Rule\", condition: {:<, [line: 44], [5, 6]}]"
    end
  end

end