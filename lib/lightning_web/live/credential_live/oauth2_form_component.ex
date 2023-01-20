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

    def changeset(schema, attrs) do
      schema
      |> cast(attrs, @fields)
    end
  end

  use LightningWeb, :live_component
  alias LightningWeb.Components.Form

  attr :on_update, :any, required: true
  attr :changeset, :map, required: true
  attr :id, :string, required: true

  def render(assigns) do
    # We need some kind of "Fake form for"
    # Check out what `form_for` emits, it's some kind of
    # Phoenix.HTML.Form struct.
    # Instead of a form tag, it should be a div with a
    # phx hook to trigger changes.
    ~H"""
    <div id={@id}>
      <%= Phoenix.HTML.Form.text_input(
        :body,
        :provider_name,
        value: Ecto.Changeset.fetch_field!(@changeset, :provider_name) |> IO.inspect() || "",
        phx_change: "validate2"
      ) %>
    </div>
    """
  end

  @impl true
  def update(%{body: body, id: id, on_update: on_update}, socket) do
    IO.inspect(body, label: "body on oauth2form update")
    schema = OAuth2Schema.new(body)
    changeset = OAuth2Schema.changeset(schema, body)

    {:ok,
     socket
     |> assign(
       changeset: changeset,
       schema: schema,
       id: id,
       on_update: on_update
     )}
  end

  @impl true
  def handle_event("validate2", params, socket) do
    changeset = OAuth2Schema.changeset(socket.assigns.schema, params["body"])
    IO.inspect(changeset, label: "validate")

    socket.assigns.on_update.(
      {changeset |> Ecto.Changeset.apply_changes() |> Map.from_struct(),
       changeset.valid?}
    )

    {:noreply, socket |> assign(changeset: changeset)}
  end
end
