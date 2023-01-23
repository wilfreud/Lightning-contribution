defmodule LightningWeb.CredentialLive.SchemaFormComponents do
  use LightningWeb, :component

  attr :changeset, :map, required: true

  def inputs_for(assigns) do
    ~H"""
    <%= for {field, _type} <- @changeset.types do %>
      <%= schema_input(@changeset, field) %>
    <% end %>
    """
  end

  attr :body_changeset, :map, required: true

  def schema_inputs(assigns) do
    ~H"""
    <%= for {field, _type} <- @body_changeset.types do %>
      <%= schema_input(@body_changeset, field) %>
    <% end %>
    """
  end

  def schema_input(schema, field) do
    properties =
      schema.root.schema
      |> Map.get("properties")
      |> Map.get(field |> to_string())

    text = properties |> Map.get("title")

    value = schema.data |> Map.get(field, nil)

    [
      label(:"credential[body]", field, text,
        class: "block text-sm font-medium text-secondary-700"
      ),
      apply(Phoenix.HTML.Form, get_input_type(properties), [
        :"credential[body]",
        field,
        [
          value: value || "",
          class: ~w(mt-1 focus:ring-primary-500 focus:border-primary-500 block
               w-full shadow-sm sm:text-sm border-secondary-300 rounded-md)
        ]
      ]),
      first_error(
        schema,
        field,
        fn error ->
          content_tag(:span, translate_error(error),
            phx_feedback_for: input_name(:"credential[body]", field),
            class: "block w-full text-sm text-secondary-700"
          )
        end
      )
    ]
  end

  defp get_input_type(properties) do
      case properties do
        %{"format" => "uri"} -> :url_input
        %{"type" => "string", "writeOnly" => true} -> :password_input
        %{"type" => "string"} -> :text_input
        %{"type" => "integer"} -> :text_input
        %{"type" => "boolean"} -> :text_input
        %{"anyOf" => [%{"type" => "string"}, %{"type" => "null"}]} -> :text_input
      end
  end

  defp first_error(schema, field, fun) do
    Enum.map(
      Enum.reduce(schema.errors |> IO.inspect(), [], fn {key, value}, acc ->
        if field == key do
          [value | acc]
        else
          acc
        end
      end)
      |> Enum.slice(0..0),
      fun
    )
  end
end
