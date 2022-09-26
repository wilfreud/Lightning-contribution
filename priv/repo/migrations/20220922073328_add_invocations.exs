defmodule Lightning.Repo.Migrations.AddInvocations do
  use Ecto.Migration

  def change do
    create table(:invocations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :project_id, references("projects", type: :binary_id), null: false

      timestamps()
    end

    execute(&copy_invocation_events/0, fn -> nil end)

    alter table("runs") do
      add :invocation_id, references("invocations", type: :binary_id)
      modify :event_id, :binary_id, null: true, from: {:binary_id, null: true}
    end

    execute(&assign_invocation_ids/0, fn -> nil end)
  end

  defp copy_invocation_events() do
    repo().query!(
      """
      INSERT INTO invocations
      (id, inserted_at, updated_at)
      SELECT e.id, e.inserted_at, e.updated_at
      FROM invocation_events e;
      """,
      [],
      log: :info
    )
  end

  defp assign_invocation_ids() do
    repo().query!(
      """
      UPDATE runs dst
      SET invocation_id=src.event_id
      FROM runs src
      WHERE src.id = dst.id;
      """,
      [],
      log: :info
    )
  end
end
