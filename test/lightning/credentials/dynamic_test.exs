defmodule Lightning.Credentials.DynamicTest do
  use Lightning.DataCase, async: true

  # alias Lightning.Credentials.Schema
  defmodule Credentials.OAuth2 do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :client_id, :string
      field :client_secret, :string

      field :user_info_url, :string
      field :token_url, :string
      field :provider_name, :string
      field :scope, :string
    end

    def changeset(schema, attrs) do
      schema
      |> cast(attrs, [
        :client_id,
        :client_secret,
        :user_info_url,
        :token_url,
        :provider_name,
        :scope
      ])
      |> validate_required([:client_id, :client_secret])
    end
  end

  defmodule CredentialSchema do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :production, :boolean
      field :body, :map
    end

    defp get_mod_opts(mod) when is_atom(mod), do: {mod, :changeset, []}
    defp get_mod_opts({mod, fun, opts}), do: {mod, fun, opts}

    @doc """
    Create an extended changeset.

    Usage:

        changeset(credential, %{}, using: Mod)

    `Mod` in this context is an embeddable schema.
    The `:using` key can also be set to an MFA for use with the `:with` option
    used by `cast_embed`. See: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3
    """
    def changeset(schema, attrs, using: mod_opts) do
      # %{name: "foo", production: false, body: %OAuth2{...}}
      # {d,
      #  CredentialSchema.__schema__(:fields)
      #  |> Enum.map(fn f -> {f, CredentialSchema.__schema__(:type, f)} end)
      #  |> Map.new()}
      {mod, fun, opts} = get_mod_opts(mod_opts)

      build_data_types(schema, mod)
      |> cast(attrs, [:name, :production])
      |> cast_embed(:body, with: {mod, fun, opts})
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

    # [id: :binary_id, foo: :string, bar: :string]
    # Dynamic.__schema__(:fields)
    # |> Enum.map(fn f -> {f, Dynamic.__schema__(:type, f)} end)
  end

  test "" do
    CredentialSchema.__schema__(:fields)
    |> Enum.map(fn f -> {f, CredentialSchema.__schema__(:type, f)} end)
    |> Map.new()
    |> IO.inspect()

    cred =
      CredentialSchema.changeset(
        %CredentialSchema{},
        %{
          "name" => "1",
          "body" => %{"nested" => "foo"}
        },
        using: {Credentials.OAuth2, :changeset, []}
      )
      |> IO.inspect()

    %CredentialSchema{name: "foo"} |> IO.inspect()
    cred |> Ecto.Changeset.apply_changes() |> IO.inspect()
  end
end
