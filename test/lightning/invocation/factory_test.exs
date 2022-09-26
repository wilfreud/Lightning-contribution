defmodule Lightning.Invocation.FactoryTest do
  use Lightning.DataCase, async: true

  alias Lightning.Invocation.Factory
  import Lightning.JobsFixtures
  import Lightning.InvocationFixtures

  describe "build/1" do
    test "handles a webhook" do
      job = job_fixture()
      dataclip = dataclip_fixture()

      invocation = Factory.build(:webhook, %{job: job, dataclip: dataclip})

      assert invocation.valid?

      {:ok, invocation} = Repo.insert(invocation)

      # assert invocation.reason.type == :webhook
      assert invocation.run.job_id == job.id
    end
  end
end
