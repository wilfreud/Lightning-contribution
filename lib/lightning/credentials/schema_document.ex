defmodule Lightning.Credentials.SchemaDocument do
  @moduledoc """
  Provides facilities to dynamically create and validate a changeset for a given
  [Schema](`Lightning.Credentials.Schema`)
  """

  alias Lightning.Credentials.Schema

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
  end

  def changeset(document, attrs, schema: schema = %Schema{}) do
    changeset =
      {document, schema.types}
      |> cast(attrs, schema.fields)

    case Schema.validate(changeset, schema) do
      :ok ->
        changeset

      {:error, errors} when is_list(errors) ->
        Enum.reduce(errors, changeset, &error_to_changeset/2)
    end
  end

  defp error_to_changeset(%{path: path, error: error}, changeset) do
    field = String.slice(path, 2..-1)

    case error do
      %{expected: "uri"} ->
        add_dynamic_error(changeset, field, "expected to be a URI")

      %{missing: fields} ->
        Enum.reduce(fields, changeset, fn field, changeset ->
          add_dynamic_error(changeset, field, "can't be blank")
        end)

      %{actual: 0, expected: _} ->
        add_dynamic_error(changeset, field, "can't be blank")

      %{actual: "null", expected: expected} when is_list(expected) ->
        add_dynamic_error(changeset, field, "can't be blank")
    end
  end

  @doc """
  A variation on `Ecto.Changeset.add_error/4` that doesn't expect atom keys.
  """
  def add_dynamic_error(
        %Ecto.Changeset{errors: errors} = changeset,
        key,
        message,
        keys \\ []
      )
      when is_binary(message) do
    %{changeset | errors: [{key, {message, keys}} | errors], valid?: false}
  end
end
