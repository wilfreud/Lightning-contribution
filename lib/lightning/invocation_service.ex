defmodule Lightning.InvocationService do
  alias Lightning.Invocation.Invocation
  alias Lightning.Repo

  @spec get(id :: Ecto.UUID.t()) :: nil | Invocation.t()
  def get(id) do
    Repo.get(Invocation, id)
  end

  @spec get_run!(Invocation.t()) :: Lightning.Invocation.Run.t()
  def get_run!(%Invocation{} = invocation) do
    Repo.one!(Ecto.assoc(invocation, :run))
  end


end
