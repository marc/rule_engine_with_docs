defmodule RuleEngineWithDocs.ResultsMap do
  use Agent

  @doc """
  Starts a new bucket that stores a Map.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end


  @doc """
  Increments the given `key` in the `bucket` by 1.
  If the key dos not exist yet, set it to 1.
  """
  def inc(bucket, key) do
    Agent.get_and_update(bucket, &Map.get_and_update(&1, key,fn val ->
      {val, cond do
        is_number(val) -> val + 1
        true -> 1
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
