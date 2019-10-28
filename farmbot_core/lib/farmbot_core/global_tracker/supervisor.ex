defmodule FarmbotCore.GlobalTracker.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init(_) do
    children = []
    Supervisor.init(children, [strategy: :one_for_one])
  end
end