defmodule Memcachex do
  @moduledoc """
  """

  use Application
  use Memcache.Api

  def start(_type, _args) do
    import Supervisor.Spec

    config_opts = Application.get_all_env(:memcachex)
    config_opts = Keyword.drop(config_opts, [:included_applications])

    children = [
      worker(Memcache.Pool, [config_opts], [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: :memxsupervisor)
  end

  def execute_k(_server, command, args, opts \\ []) do
    {pid, module} = get_pid_and_module
    module.execute_k(pid, command, args, opts)
  end

  def execute_kv(_server, command, args, opts) do
    {pid, module} = get_pid_and_module
    module.execute_kv(pid, command, args, opts)
  end

  def execute(_server, command, args, opts \\ []) do
    {pid, module} = get_pid_and_module
    module.execute(pid, command, args, opts)
  end

  defp get_pid_and_module do
    [{_id, pid, :worker, [mod]}] = Supervisor.which_children(:memxsupervisor)
    {pid, mod}
  end

end
