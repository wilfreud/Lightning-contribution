defmodule Lightning.Invocations.InvocationTest do
  use Lightning.DataCase, async: true

  alias Lightning.Invocations.Invocation
  import Lightning.ProjectsFixtures
  import Lightning.JobsFixtures

  describe "changeset/2" do
    test "expects a project_id" do
      changeset = Invocation.changeset(%Invocation{}, %{})

      assert "can't be blank" in errors_on(changeset).project_id
    end

    test "can cast a run" do
      project = project_fixture()

      changeset =
        Invocation.changeset(%Invocation{}, %{project_id: project.id, run: %{}})

      assert {:job_id, ["can't be blank"]} in errors_on(changeset).run

      job = job_fixture(project_id: project.id)

      changeset =
        Invocation.changeset(%Invocation{}, %{
          project_id: project.id,
          run: %{
            job_id: job.id
          }
        })

      {:ok, _invocation} = Repo.insert(changeset)
    end
  end
end
