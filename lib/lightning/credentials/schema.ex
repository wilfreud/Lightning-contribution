defmodule Lightning.Credentials.Schema do
  # @moduledoc """
  # Structure that can parse JsonSchemas (using `ExJsonSchema`) and validate
  # changesets for a given schema.
  # """

  alias ExJsonSchema.Validator

  @type t :: %__MODULE__{
          name: String.t() | nil,
          root: ExJsonSchema.Schema.Root.t(),
          types: Ecto.Changeset.types(),
          fields: [String.t()],
          data: %{String.t() => any},
          valid?: boolean,
          errors: [{String.t(), {String.t(), Keyword.t()}}]
        }

  defstruct [:name, :root, :types, :fields, :data, :valid?, :errors]

  @spec new(
          json_schema :: %{String.t() => any()},
          data :: %{String.t() => any},
          name :: String.t() | nil
        ) :: __MODULE__.t()
  def new(json_schema, data, name \\ nil) when is_map(json_schema) do
    root = ExJsonSchema.Schema.resolve(json_schema)
    types = get_types(root)
    fields = Map.keys(types)

    struct!(__MODULE__,
      name: name,
      root: root,
      types: types,
      fields: fields,
      valid?: true,
      errors: []
    )
    |> change(data)
  end

  def change(%__MODULE__{} = schema, attrs) do
    schema
    |> put_data(attrs)
    |> validate()
  end

  def put_data(%__MODULE__{} = schema, attrs) do
    data =
      Enum.map(attrs, fn {k, v} ->
        case v do
          # nillify blank strings coming from forms
          "" -> {k, nil}
          v -> {k, v}
        end
      end)
      |> Map.new()

    %{schema | data: data}
  end

  @spec validate(schema :: __MODULE__.t()) :: __MODULE__.t()
  def validate(%__MODULE__{} = schema) do
    Validator.validate(
      schema.root,
      schema.data,
      error_formatter: false
    )
    |> case do
      :ok ->
        %{schema | valid?: true, errors: []}

      {:error, errors} when is_list(errors) ->
        Enum.reduce(errors, %{schema | errors: []}, &apply_errors/2)
    end
  end

  defp apply_errors(%{path: path, error: error}, schema) do
    field = String.slice(path, 2..-1)

    case error do
      %{expected: "uri"} ->
        add_error(schema, field, "expected to be a URI")

      %{missing: fields} ->
        Enum.reduce(fields, schema, fn field, schema ->
          add_error(schema, field, "can't be blank")
        end)

      %{actual: 0, expected: _} ->
        add_error(schema, field, "can't be blank")

      %{actual: "null", expected: expected} when is_list(expected) ->
        add_error(schema, field, "can't be blank")
    end
  end

  @doc """
  A variation on `Ecto.Changeset.add_error/4` that doesn't expect atom keys.
  """
  def add_error(
        %__MODULE__{errors: errors} = schema,
        key,
        message,
        keys \\ []
      )
      when is_binary(message) do
    %{schema | errors: [{key, {message, keys}} | errors], valid?: false}
  end

  defp get_types(root) do
    root.schema
    |> Map.get("properties", [])
    |> Enum.map(fn {k, properties} ->
      {k, Map.get(properties, "type", "string") |> String.to_atom()}
    end)
    |> Enum.reverse()
    |> Map.new()
  end

  defp ensure_string_map(%{__struct__: _} = data) do
    Map.from_struct(data) |> ensure_string_map()
  end

  defp ensure_string_map(data) do
    stringify_keys(data)
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
