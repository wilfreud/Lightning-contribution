defmodule Lightning.Repo.Migrations.MoveDataclipsToRun do
  use Ecto.Migration

  def change do
    alter table("runs") do
      add :input_dataclip_id, references("dataclips", type: :binary_id), null: false
      add :output_dataclip_id, references("dataclips", type: :binary_id)
    end

    execute(&update_runs/0, fn -> nil end)
  end

  defp update_runs() do
    repo().query!(
      """
      UPDATE runs
      SET input_dataclip_id=subquery.input_dataclip_id,
          output_dataclip_id=subquery.output_dataclip_id
      FROM (
        SELECT r.id, e.dataclip_id AS input_dataclip_id, d.id AS output_dataclip_id
        FROM runs r
        LEFT JOIN invocation_events e ON r.event_id = e.id
        LEFT JOIN dataclips d ON d.source_event_id = e.id
      ) AS subquery
      WHERE runs.id = subquery.id;
      """,
      [],
      log: :info
    )
  end
end
