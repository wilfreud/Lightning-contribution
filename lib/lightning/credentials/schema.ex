defmodule Lightning.Credentials.Schema do
  @moduledoc """
  Structure that can parse JsonSchemas (using `ExJsonSchema`) and validate
  changesets for a given schema.
  """

  alias ExJsonSchema.Validator

  @type t :: %__MODULE__{
          name: String.t() | nil,
          root: ExJsonSchema.Schema.Root.t(),
          types: Ecto.Changeset.types(),
          fields: [String.t()]
        }

  defstruct [:name, :root, :types, :fields]

  @spec new(json_schema :: %{String.t() => any()}, name :: String.t() | nil) ::
          __MODULE__.t()
  def new(json_schema, name \\ nil) when is_map(json_schema) do
    root = ExJsonSchema.Schema.resolve(json_schema)
    types = get_types(root)
    fields = Map.keys(types)

    struct!(__MODULE__, name: name, root: root, types: types, fields: fields)
  end

  @spec validate(changeset :: Ecto.Changeset.t(), schema :: __MODULE__.t()) ::
          :ok | {:error, [any()]}
  def validate(changeset, %__MODULE__{} = schema) do
    Validator.validate(
      schema.root,
      Ecto.Changeset.apply_changes(changeset)
      |> Map.from_struct()
      |> stringify_keys(),
      error_formatter: false
    )
  end

  defp get_types(root) do
    root.schema
    |> Map.get("properties", [])
    |> Enum.map(fn {k, properties} ->
      {k |> String.to_atom(),
       Map.get(properties, "type", "string") |> String.to_atom()}
    end)
    |> Enum.reverse()
    |> Map.new()
  end

  defp stringify_keys(data) when is_map(data) do
    Enum.reduce(data, %{}, fn
      {key, value}, acc when is_atom(key) ->
        Map.put(acc, key |> to_string(), value)

      {key, value}, acc when is_binary(key) ->
        Map.put(acc, key, value)
    end)
  end
end
