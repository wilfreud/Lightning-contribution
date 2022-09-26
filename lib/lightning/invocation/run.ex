defmodule Lightning.Invocation.Run do
  @moduledoc """
  Ecto model for Runs.

  A run represents the results of an Invocation.Event, where the Event
  stores what triggered the Run, the Run itself represents the execution.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Lightning.Invocation.{Dataclip, Event}
  alias Lightning.Invocations.Invocation
  alias Lightning.Jobs.Job

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: Ecto.UUID.t() | nil,
          event: Event.t() | Ecto.Association.NotLoaded.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "runs" do
    field :exit_code, :integer
    field :finished_at, :utc_datetime_usec
    field :log, {:array, :string}
    field :started_at, :utc_datetime_usec

    belongs_to :event, Event
    belongs_to :invocation, Invocation
    belongs_to :job, Job

    belongs_to :input_dataclip, Dataclip
    belongs_to :output_dataclip, Dataclip

    timestamps(usec: true)
  end

  @doc false
  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :log,
      :exit_code,
      :started_at,
      :finished_at,
      :event_id,
      :input_dataclip_id,
      :output_dataclip_id,
      :invocation_id,
      :job_id
    ])
    |> validate_required([:job_id])
    |> assoc_constraint(:invocation)
    |> assoc_constraint(:job)
    |> foreign_key_constraint(:input_dataclip)
    |> foreign_key_constraint(:output_dataclip)
    |> foreign_key_constraint(:invocation)
    |> foreign_key_constraint(:job)
  end
end
