defmodule RuleEngineWithDocs.ResultsList do
  use Agent

  @doc """
  Starts a new bucket that stores a List.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end)
  end

  @doc """
  Prepends `value` to the `bucket`.
  """
  def prepend(bucket, value) do
    Agent.update(bucket, fn list -> [value | list] end)
  end

  @doc """
  Appends `value` to the `bucket`.
  """
  def append(bucket, value) do
    Agent.update(bucket, fn list -> list ++ [value] end)
  end

  @doc """
  Returns List stored by `bucket`.
  """
  def get_list(bucket) do
    Agent.get(bucket, fn list -> list end)
  end

  @doc """
  Turns a List of messages into a map.

  Sample List:
  [
    {:error, :email, "Sample 1 email cannot be blank."}
    {:error, :name, "Sample 1 name must be at least 4 characters in length."}
    {:error, :name, "Sample 1 name contains an invalid character."}
    {:notice, :phone, "Sample 1 phone format is invalid."}
  ]

  Resulting Map returned for the sample List:
  %{
    error: %{
      email: ["Sample 1 email cannot be blank."],
      name: ["Sample 1 name must be at least 4 characters in length.", "Sample 1 name contains an invalid character."]
    },
    notice: %{phone: ["Sample 1 phone format is invalid."]
  }
  """
  def get_messages_map(bucket) do
    messages = Agent.get(bucket, fn list -> list end)
    types = Enum.uniq(
      Enum.map(messages, fn({type,_field,_message}) ->
        type
      end)
    )
    map = Map.new(types, fn type -> {type, %{}} end)
    map = Enum.reduce(types, map, fn type, map_acc ->
      type_messages = Enum.filter_map(messages, fn({msg_type,field,message}) -> msg_type == type end, &(  tl(Tuple.to_list(&1))  ))
      fields = Enum.uniq(
        Enum.map(type_messages, fn([field,_message]) ->
          field
        end)
      )
      type_map = Map.new(fields, fn field -> {field, []} end)
      type_map = Enum.reduce(type_messages, type_map, fn [field,message], acc ->
        update_in acc[field], &(&1 ++ [message])
      end)
      map_acc = update_in map_acc[type], &(type_map || &1)
    end)
    map
  end

end
