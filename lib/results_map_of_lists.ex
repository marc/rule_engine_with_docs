defmodule RuleEngineWithDocs.ResultsMapOfLists do
  use Agent

  @doc """
  Starts a new bucket that stores a Map of Lists.

  Sample Map of Lists:
  %{
    key1: ["a", "b"],
    key2: ["z"]
  }
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a List from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Adds an new value to a List from the `bucket` by `key` and sorts the List.
  """
  def add(bucket, key, newval) do
    Agent.get_and_update(bucket, &Map.get_and_update(&1, key,fn val ->
      {val, cond do
        is_list(val) -> Enum.sort [newval | val]
        true -> [newval]
      end}
    end))
  end

  @doc """
  Returns Map stored by `bucket`.
  """
  def get_map(bucket) do
    Agent.get(bucket, fn map -> map end)
  end

end
