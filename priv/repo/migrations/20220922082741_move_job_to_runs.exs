defmodule Lightning.Repo.Migrations.MoveJobToRuns do
  use Ecto.Migration

  def change do
    alter table("runs") do
      add :job_id, references("jobs", type: :binary_id), null: false
    end

    execute(&update_runs/0, fn -> nil end)
  end

  defp update_runs() do
    repo().query!(
      """
      UPDATE runs
      SET job_id=subquery.job_id
      FROM (
        SELECT r.id,
               e.job_id
        FROM runs r
        LEFT JOIN invocation_events e ON r.event_id = e.id
      ) AS subquery
      WHERE runs.id = subquery.id;
      """,
      [],
      log: :info
    )
  end
end
