defmodule Lightning.Credentials.CredentialForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :production, :boolean
    field :body, :map
  end

  @doc """
  Create an extended changeset.

  Usage:

      changeset(credential, %{}, using: Mod)

  `Mod` in this context is an embeddable schema.
  The `:using` key can also be set to an MFA for use with the `:with` option
  used by `cast_embed`. See: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3
  """
  def changeset(credential, attrs, using: mod_opts) do
    # %{name: "foo", production: false, body: %OAuth2{...}}
    # {d,
    #  CredentialForm.__schema__(:fields)
    #  |> Enum.map(fn f -> {f, CredentialForm.__schema__(:type, f)} end)
    #  |> Map.new()}
    {mod, fun, opts} = get_mod_opts(mod_opts)

    build_data_types(credential, mod)
    |> cast(attrs, [:name, :production])
    |> cast_embed(:body, with: {mod, fun, opts})
    |> validate_required([:name])
  end

  defp build_data_types(data, related) do
    {data,
     %{
       name: :string,
       production: :boolean,
       body:
         {:embed,
          Ecto.Embedded.init(
            cardinality: :one,
            related: related,
            owner: __MODULE__,
            field: :body,
            on_replace: :delete
          )}
     }}
  end

  defp get_mod_opts(mod) when is_atom(mod), do: {mod, :changeset, []}
  defp get_mod_opts({mod, fun, opts}), do: {mod, fun, opts}
end
