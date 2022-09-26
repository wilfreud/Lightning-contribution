defmodule Lightning.Invocation.Invocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightning.Projects.Project
  alias Lightning.Invocation.{Run}

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: Ecto.UUID.t() | nil,
          run: Run.t() | Ecto.Association.NotLoaded.t() | nil,
          project: Project.t() | Ecto.Association.NotLoaded.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invocations" do
    has_one :run, Run
    belongs_to :project, Project

    timestamps(usec: true)
  end

  @doc false
  def changeset(invocation, attrs) do
    invocation
    |> cast(attrs, [:project_id])
    |> cast_assoc(:run, with: &Run.changeset/2)
    |> validate_required([:project_id])
    |> assoc_constraint(:project)
  end
end
