defmodule Lightning.Credentials.DynamicTest do
  use Lightning.DataCase, async: true

  # alias Lightning.Credentials.Schema
  defmodule Sub do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :nested, :string
    end

    def changeset(schema, attrs) do
      schema |> cast(attrs, [:nested])
    end
  end

  defmodule Dynamic do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :production, :boolean
      embeds_one :body, Sub
    end

    def changeset(d, attrs) do
      d |> cast(attrs, [:foo, :bar]) |> cast_embed(:body)
    end

    def changeset_two(d, attrs) do
      # %{name: "foo", production: false, body: %OAuth2{...}}
      # {d,
      #  Dynamic.__schema__(:fields)
      #  |> Enum.map(fn f -> {f, Dynamic.__schema__(:type, f)} end)
      #  |> Map.new()}
      {d,
       %{
         name: :string,
         production: :boolean,
         body:
           {:embed,
            %Ecto.Embedded{
              cardinality: :one,
              field: :body,
              owner: Lightning.Credentials.DynamicTest.Dynamic,
              related: Lightning.Credentials.DynamicTest.Sub,
              on_cast: nil,
              on_replace: :raise,
              unique: true,
              ordered: true
            }}
       }}
      |> cast(attrs, [:name, :production])
      |> cast_embed(:body)
    end

    # [id: :binary_id, foo: :string, bar: :string]
    # Dynamic.__schema__(:fields)
    # |> Enum.map(fn f -> {f, Dynamic.__schema__(:type, f)} end)
  end

  test "" do
    Dynamic.__schema__(:fields)
    |> Enum.map(fn f -> {f, Dynamic.__schema__(:type, f)} end)
    |> Map.new()

    Dynamic.changeset_two(%Dynamic{}, %{
      "name" => "1",
      "body" => %{"nested" => "foo"}
    })
    |> IO.inspect()
  end
end
