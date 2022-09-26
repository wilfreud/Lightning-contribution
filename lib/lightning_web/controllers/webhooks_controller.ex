defmodule LightningWeb.WebhooksController do
  use LightningWeb, :controller

  alias Lightning.{Jobs, Invocation, Pipeline}

  @spec create(Plug.Conn.t(), %{path: binary()}) :: Plug.Conn.t()
  def create(conn, %{"path" => path}) do
    path
    |> Enum.join("/")
    |> Jobs.get_job_by_webhook()
    |> case do
      nil ->
        put_status(conn, :not_found)
        |> json(%{})

      job ->
        {:ok, %{invocation: invocation, dataclip: _dataclip}} =
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            :dataclip,
            Invocation.Dataclip.changeset(%Invocation.Dataclip{}, %{
              type: :http_request,
              body: conn.body_params,
              project_id: job.project_id
            })
          )
          |> Ecto.Multi.insert(:invocation, fn %{dataclip: dataclip} ->
            Invocation.Factory.build(:webhook, %{job: job, dataclip: dataclip})
          end)
          |> Lightning.Repo.transaction()

        resp = %{invocation_id: invocation.id, run_id: invocation.run.id}

        Pipeline.new(%{invocation_id: invocation.id})
        |> Oban.insert()

        conn
        |> json(resp)
    end
  end
end
