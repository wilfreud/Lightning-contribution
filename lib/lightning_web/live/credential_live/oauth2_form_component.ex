defmodule LightningWeb.CredentialLive.Oauth2FormComponent do
  defmodule OAuth2Schema do
    use Ecto.Schema

    embedded_schema do
      field :client_id, :string
      field :client_secret, :string

      field :user_info_url, :string
      field :token_url, :string
      field :provider_name, :string
      field :scope, :string
    end
  end

  use LightningWeb, :live_component

  attr :on_update, :any, required: true

  def render(assigns) do
    ~H"""
    <p>I'm OAuth2</p>
    """
  end
end
