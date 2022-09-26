defmodule Lightning.Invocation.Factory do
  alias Lightning.Invocation.Invocation

  def build(:webhook, %{job: job, dataclip: dataclip}) do
    Invocation.changeset(%Invocation{}, %{
      project_id: job.project_id,
      run: %{job_id: job.id, input_dataclip_id: dataclip.id}
    })
  end

  # success or fail
  def build(_, job, run) do
    input_dataclip_id = get_next_dataclip_id(run)

    Invocation.changeset(%Invocation{}, %{
      project_id: job.project_id,
      run: %{job_id: job.id, input_dataclip_id: input_dataclip_id}
    })
  end

  def get_next_dataclip_id(%{exit_code: 0, output_dataclip_id: id}), do: id
  def get_next_dataclip_id(%{exit_code: _, input_dataclip_id: id}), do: id
end
