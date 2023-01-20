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
      |> validate_required([:provider_name])
    |> validate_format(:provider_name, ~r/^[a-z\-\d]+$/)
    end
  end

  use LightningWeb, :live_component
  alias LightningWeb.Components.Form

  attr :on_update, :any, required: true
  attr :changeset, :map, required: true
  attr :id, :string, required: true

  def render(assigns) do
    assigns = assign(assigns, form: Phoenix.HTML.FormData.to_form(assigns.changeset |> IO.inspect(), as: "body"))

    ~H"""
    <div>
      <Form.text_field form={@form} id={:provider_name} label="Provider Name" />
    </div>
    """
  end

    # # We need some kind of "Fake form for"
    # # Check out what `form_for` emits, it's some kind of
    # # Phoenix.HTML.Form struct.
    # # Instead of a form tag, it should be a div with a
    # # phx hook to trigger changes.
    # ~H"""
    # <div>
    #   <.isolated_form id={@id} :let={f} for={@changeset} phx-target={@myself} phx-change="validate">
    #     <Form.text_field form={f} id={:provider_name} label="Provider Name" />
    #   </.isolated_form>
    # </div>
    # """
  attr :for, :any, required: true, doc: "The form source data."
  attr :id, :string
  attr :rest, :global

  def isolated_form(assigns) do
    form_for =
      assigns[:for] || raise ArgumentError, "missing :for assign to form"

    form = Phoenix.HTML.FormData.to_form(form_for, [])

    assigns = assigns |> assign(form: form)

    ~H"""
    <div phx-hook="IsolatedForm" id={@id} {@rest}>
      <%= render_slot(@inner_block, @form) %>
    </div>
    """
  end

  @impl true
  def update(%{body: body, id: id, on_update: on_update}, socket) do
    IO.inspect(body, label: "body on oauth2form update")
    changeset = OAuth2Schema.changeset(%OAuth2Schema{}, body) |> Map.put(:action, :validate)

    {:ok,
     socket
     |> assign(
       changeset: changeset,
       id: id,
       on_update: on_update
     )}
  end


  @impl true
  def handle_event("validate", params, socket) do
    IO.inspect(params)
    changeset = OAuth2Schema.changeset(%OAuth2Schema{}, params["body"])
    IO.inspect(changeset, label: "validate")

    socket.assigns.on_update.(
      {changeset |> Ecto.Changeset.apply_changes() |> Map.from_struct(),
       changeset.valid?}
    )

    {:noreply, socket |> assign(changeset: changeset)}
  end
end
