defmodule Lightning.Credentials.CredentialFormTest do
  use Lightning.DataCase, async: true

  alias Lightning.Credentials.CredentialForm

  test "" do
    # CredentialForm.__schema__(:fields)
    # |> Enum.map(fn f -> {f, CredentialForm.__schema__(:type, f)} end)
    # |> Map.new()
    # |> IO.inspect()

    schema_map =
      """
      {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "properties": {
          "username": {
            "type": "string",
            "description": "The username used to log in"
          },
          "password": {
            "type": "string",
            "description": "The password used to log in",
            "writeOnly": true
          },
          "hostUrl": {
            "type": "string",
            "description": "The password used to log in",
            "format": "uri"
          },
          "number": {
            "type": "integer",
            "description": "A number to log in"
          }
        },
        "type": "object",
        "additionalProperties": true,
        "required": ["hostUrl", "password", "username", "number"]
      }
      """
      |> Jason.decode!()

    schema = Lightning.Credentials.Schema.new(schema_map)

    changeset =
      CredentialForm.changeset(
        %{},
        %{"name" => "1", "body" => %{"nested" => "foo", "hostUrl" => "nope"}},
        using:
          {Lightning.Credentials.SchemaDocument, :changeset, [[schema: schema]]}
      )

    errors = errors_on(changeset)
    assert {"username", ["can't be blank"]} in errors.body
    assert {"hostUrl", ["expected to be a URI"]} in errors.body
    assert {"number", ["can't be blank"]} in errors.body

    refute changeset.valid?

    # Lightning.Credentials.Credential.changeset(
    #   %Lightning.Credentials.Credential{},
    #   %{}
    # )
    # |> Ecto.Changeset.put_embed(
    #   :body,
    #   Lightning.Credentials.SchemaDocument.changeset(
    #     %{},
    #     %{"nested" => "foo", "hostUrl" => "nope"},
    #     schema: schema
    #   )
    # )
  end
end
