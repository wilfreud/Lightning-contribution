defmodule LightningWeb.CredentialLive.Edit do
  @moduledoc """
  LiveView for editing a single Credential, which inturn uses
  `LightningWeb.CredentialLive.FormComponent` for common functionality.
  """
  use LightningWeb, :live_view

  alias Lightning.Credentials
  alias Lightning.Credentials.Credential
  alias Lightning.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Credential")
    |> assign(
      credential:
        Credentials.get_credential!(id)
        |> Lightning.Repo.preload(:project_credentials),
      projects: list_projects(socket),
      users: list_users()
    )
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign(:page_title, "New Credential")
    |> assign(
      credential: %Credential{user_id: socket.assigns.current_user.id},
      projects: list_projects(socket)
    )
    |> maybe_assign_params(params)
  end

  defp maybe_assign_params(socket, params) do
    caller_context = params

    # return_to is a function that returns a project_workflow_path patched with the newly created project_credential and return

    if caller_context do
      project = get_project(params["project"])

      socket
      |> assign(
        caller_context: %{
          "name" => project.name,
          "project_id" => params["project"],
          "job_id" => params["job"]
        },
        return_to: fn socket, credential ->
          project_credential =
            get_project_credential(params["project"], credential.id)

          socket
          |> get_project_workflow_route(params)
          |> merge_uri_query(%{
            "project_credential_id" => project_credential.id
          })
        end
      )
    else
      socket
      |> assign(return_to: Routes.credential_index_path(socket, :index))
    end
  end

  defp get_project_workflow_route(socket, params) do
    cond do
      params["job"] ->
        Routes.project_workflow_path(
          socket,
          :edit_job,
          params["project"],
          params["job"]
        )

      params["upstream_job"] ->
        Routes.project_workflow_path(
          socket,
          :new_job,
          params["project"],
          %{"upstream_id" => params["upstream_job"]}
        )

      true ->
        Routes.project_workflow_path(
          socket,
          :new_job,
          params["project"]
        )
    end
  end

  def merge_uri_query(path, query_params) when is_binary(path) do
    IO.inspect(path, label: "URL")

    URI.new!(path)
    |> append_query(query_params)
    |> URI.to_string()
  end

  def append_query(%URI{} = uri, query) when is_map(query) do
    uri
    |> append_query(URI.encode_query(query))
    |> IO.inspect()
  end

  def append_query(%URI{} = uri, query) when is_binary(query) do
    q = uri.query || ""

    if String.ends_with?(q, "&") do
      %{uri | query: q <> query}
    else
      %{uri | query: q <> "&" <> query}
    end
  end

  defp apply_action(socket, :transfer_ownership, %{"id" => id}) do
    socket
    |> assign(:page_title, "Transfer Credential Ownership")
    |> assign(
      credential:
        Credentials.get_credential!(id)
        |> Lightning.Repo.preload(:project_credentials),
      projects: list_projects(socket)
    )
  end

  defp get_project_credential(project_id, credential_id) do
    Projects.get_project_credential(project_id, credential_id)
  end

  defp list_projects(socket) do
    Projects.get_projects_for_user(socket.assigns.current_user)
  end

  defp get_project(project_id) do
    Projects.get_project(project_id)
  end

  defp list_users() do
    Lightning.Accounts.list_users()
  end
end
