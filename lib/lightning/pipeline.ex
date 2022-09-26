defmodule Lightning.Pipeline do
  @moduledoc """
  Service class to coordinate the running of jobs, and their downstream jobs.
  """
  use Oban.Worker,
    queue: :runs,
    priority: 1,
    max_attempts: 1

  require Logger

  alias Lightning.Pipeline.Runner

  alias Lightning.{Jobs, InvocationService}
  alias Lightning.Invocation.{Invocation, Factory}
  alias Lightning.Repo
  import Ecto.Query, only: [select: 3]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"invocation_id" => id}}) do
    InvocationService.get(id)
    |> process()

    :ok
  end

  @spec process(Invocation.t()) :: :ok
  def process(%Invocation{} = invocation) do
    run = InvocationService.get_run!(invocation)
    result = Runner.start(run)

    jobs = get_jobs_for_result(run.job_id, result)

    if length(jobs) > 0 do
      jobs
      |> Enum.each(fn job ->
        invocation =
          Factory.build(
            :flow,
            job,
            run |> Repo.reload!()
          )
          |> Repo.insert!()

        new(%{invocation_id: invocation.id})
        |> Oban.insert()
      end)
    end

    :ok
  end

  defp result_to_trigger_type(%Engine.Result{exit_reason: reason}) do
    case reason do
      :error -> :on_job_failure
      :ok -> :on_job_success
      _ -> nil
    end
  end

  defp get_jobs_for_result(upstream_job_id, result) do
    Jobs.get_downstream_jobs_for(upstream_job_id, result_to_trigger_type(result))
  end

  defp get_next_dataclip_id(result, run) do
    case result.exit_reason do
      :error ->
        Invocation.get_dataclip_query(run)
        |> select([d], d.id)
        |> Repo.one()

      :ok ->
        Invocation.get_result_dataclip_query(run)
        |> select([d], d.id)
        |> Repo.one()
    end
  end
end
