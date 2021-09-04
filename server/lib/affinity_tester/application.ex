defmodule AffinityTester.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {AffinityTester, []}
    ]
    opts = [strategy: :one_for_one, name: AffinityTester.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
