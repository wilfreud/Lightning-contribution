defmodule LightningWeb.DataclipLive.Edit do
  @moduledoc """
  LiveView for editing a single dataclip.
  """
  use LightningWeb, :live_view

  alias Lightning.Credentials
  alias Lightning.Invocation
  alias Lightning.Invocation.Dataclip
  alias Lightning.Scrubber

  on_mount {LightningWeb.Hooks, :project_scope}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(active_menu_item: :dataclips)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    dataclip = Invocation.get_dataclip_details!(id)

    socket
    |> assign(:page_title, "Edit Dataclip")
    |> assign(:dataclip, maybe_scrub(dataclip))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Dataclip")
    |> assign(:dataclip, %Dataclip{project_id: socket.assigns.project.id})
  end

  defp maybe_scrub(
         %{type: :run_result, source_run: %{credential_id: credential_id}} =
           dataclip
       )
       when is_binary(credential_id) do
    credential = Credentials.get_credential!(credential_id)
    samples = Credentials.sensitive_values_for(credential)
    basic_auth = Credentials.basic_auth_for(credential)

    {:ok, scrubber} =
      Scrubber.start_link(
        samples: samples,
        basic_auth: basic_auth
      )

    %{dataclip | body: Scrubber.scrub(scrubber, dataclip.body)}
  end

  defp maybe_scrub(dataclip), do: dataclip
end
