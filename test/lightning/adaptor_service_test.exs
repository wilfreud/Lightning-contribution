defmodule Lightning.AdaptorServiceTest do
  use ExUnit.Case, async: true
  alias Lightning.AdaptorService

  def mock_adaptors() do
    [
      %Lightning.AdaptorService.Adaptor{
        name: "@openfn/language-http",
        version: "1.0.0",
        path: "/test/path/adaptor1",
        status: :present,
        local_name: "@openfn/language-http"
      },
      %Lightning.AdaptorService.Adaptor{
        name: "@openfn/language-ftp",
        version: "latest",
        path: "/test/path/adaptor2",
        status: :present,
        local_name: "@openfn/language-ftp"
      }
    ]
  end

  setup do
    agent = start_supervised!({Agent, fn -> %{adaptors: mock_adaptors()} end})

    {:ok, agent: agent}
  end

  describe "find_adaptor/2" do
    test "find_adaptor with version 'latest'", %{agent: agent} do
      result = AdaptorService.find_adaptor(agent, "@openfn/language-ftp@latest")
      assert result.version == "latest"
      assert result.name == "@openfn/language-ftp"
    end

    test "find_adaptor with specific version", %{agent: agent} do
      result = AdaptorService.find_adaptor(agent, "@openfn/language-http@1.0.0")
      assert result.version == "1.0.0"
      assert result.name == "@openfn/language-http"
    end

    test "find_adaptor with non-existing version", %{agent: agent} do
      result = AdaptorService.find_adaptor(agent, "@openfn/language-http@3.0.0")
      assert result == nil
    end
  end
end
