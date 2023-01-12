defmodule LightningWeb.CredentialLive.SchemaFormComponents do
  use LightningWeb, :component
  import Ecto.Changeset, only: [get_field: 3]
  alias Lightning.Credentials.Schema

  attr :schema, :map, required: true
  attr :schema_changeset, :map, required: true

  def schema_inputs(assigns) do
    ~H"""
    <%= for {field, _type} <- @schema.types do %>
      <%= schema_input(@schema, @schema_changeset, field) %>
    <% end %>
    """
  end

  def schema_input(%Schema{} = schema, changeset, field) do
    properties =
      schema.root.schema
      |> Map.get("properties")
      |> Map.get(field |> to_string())

    text = properties |> Map.get("title")

    type =
      case properties do
        %{"format" => "uri"} -> :url_input
        %{"type" => "string", "writeOnly" => true} -> :password_input
        %{"type" => "string"} -> :text_input
        %{"type" => "integer"} -> :text_input
        %{"type" => "boolean"} -> :text_input
        %{"anyOf" => [%{"type" => "string"}, %{"type" => "null"}]} -> :text_input
      end

    value = changeset |> get_field(field, nil)

    [
      label(:body, field, text,
        class: "block text-sm font-medium text-secondary-700"
      ),
      apply(Phoenix.HTML.Form, type, [
        :body,
        field,
        [
          value: value || "",
          class: ~w(mt-1 focus:ring-primary-500 focus:border-primary-500 block
               w-full shadow-sm sm:text-sm border-secondary-300 rounded-md)
        ]
      ]),
      Enum.map(
        Keyword.get_values(changeset.errors, field) |> Enum.slice(0..0),
        fn error ->
          content_tag(:span, translate_error(error),
            phx_feedback_for: input_id(:body, field),
            class: "block w-full"
          )
        end
      )
    ]
  end
end
