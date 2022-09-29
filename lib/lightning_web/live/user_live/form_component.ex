defmodule LightningWeb.UserLive.FormComponent do
  @moduledoc """
  Form component for creating and editing users
  """
  use LightningWeb, :live_component

  alias Lightning.Accounts
  import Ecto.Changeset, only: [fetch_field!: 2, put_assoc: 3, get_field: 3]
  import LightningWeb.Components.Form
  import LightningWeb.Components.Common

  @impl true
  def update(%{user: user, projects: projects} = assigns, socket) do
    changeset = Accounts.change_user_details(user)
    all_projects = projects |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(
       available_projects: filter_available_projects(changeset, all_projects),
       selected_project: ""
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_details(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  @impl true
  def handle_event(
        "select_item",
        %{"id" => project_id},
        socket
      ) do
    {:noreply, socket |> assign(selected_project: project_id)}
  end

  @impl true
  def handle_event(
        "add_new_project",
        %{"projectid" => project_id},
        socket
      ) do
    project_users = fetch_field!(socket.assigns.changeset, :project_users)

    project_users =
      Enum.find(project_users, fn pu -> pu.project_id == project_id end)
      |> if do
        project_users
        |> Enum.map(fn pu ->
          if pu.project_id == project_id do
            Ecto.Changeset.change(pu, %{delete: false})
          end
        end)
      else
        project_users
        |> Enum.concat([
          %Lightning.Projects.ProjectUser{project_id: project_id}
        ])
      end

    changeset =
      socket.assigns.changeset
      |> put_assoc(:project_users, project_users)
      |> Map.put(:action, :validate)

    available_projects =
      filter_available_projects(changeset, socket.assigns.all_projects)

    {:noreply,
     socket
     |> assign(
       changeset: changeset,
       available_projects: available_projects,
       selected_project: ""
     )}
  end

  @impl true
  def handle_event("delete_project", %{"index" => index}, socket) do
    index = String.to_integer(index)

    project_users_params =
      fetch_field!(socket.assigns.changeset, :project_users)
      |> Enum.with_index()
      |> Enum.reduce([], fn {pu, i}, project_users ->
        if i == index do
          if is_nil(pu.id) do
            project_users
          else
            [Ecto.Changeset.change(pu, %{delete: true}) | project_users]
          end
        else
          [pu | project_users]
        end
      end)

    changeset =
      socket.assigns.changeset
      |> put_assoc(:project_users, project_users_params)
      |> Map.put(:action, :validate)

    available_projects =
      filter_available_projects(changeset, socket.assigns.all_projects)

    {:noreply,
     socket
     |> assign(changeset: changeset, available_projects: available_projects)}
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user_details(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp filter_available_projects(changeset, all_projects) do
    existing_ids =
      fetch_field!(changeset, :project_users)
      |> Enum.reject(fn pu -> pu.delete end)
      |> Enum.map(fn pu -> pu.user_id end)

    all_projects
    |> Enum.reject(fn {_, user_id} -> user_id in existing_ids end)
  end
end
