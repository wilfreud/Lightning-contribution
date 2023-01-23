defmodule LightningWeb.CredentialLive.Oauth2FormComponent do
  defmodule OAuth2Schema do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :client_id, :string
      field :client_secret, :string

      field :user_info_url, :string
      field :token_url, :string
      field :provider_name, :string
      field :scope, :string
    end

    @fields [
      :client_id,
      :client_secret,
      :user_info_url,
      :token_url,
      :provider_name,
      :scope
    ]

    def new(attrs) do
      struct!(__MODULE__, attrs || %{})
    end

    def changeset(schema \\ %__MODULE__{}, attrs) do
      schema
      |> cast(attrs, @fields)
      |> validate_required(@fields)
    end
  end

  use LightningWeb, :component
  alias LightningWeb.Components.Form

  attr :changeset, :map, required: true

  def inputs_for(assigns) do
    assigns =
      assigns
      |> assign(
        form:
          Phoenix.HTML.FormData.to_form(assigns.changeset, as: "credential[body]")
      )

    ~H"""
    <Form.text_field form={@form} label="Client ID" id={:client_id} />
    <Form.password_field
      form={@form}
      label="Client Secret"
      id={:client_secret}
      value={input_value(@form, :client_secret)}
    />
    <br />
    <Form.text_field form={@form} label="User Info URL" id={:user_info_url} />
    <Form.text_field form={@form} label="Token URL" id={:token_url} />
    <Form.text_field form={@form} label="Scope" id={:scope} />
    <br />
    <Form.text_field form={@form} label="Provider Name" id={:provider_name} />
    """
  end
end
