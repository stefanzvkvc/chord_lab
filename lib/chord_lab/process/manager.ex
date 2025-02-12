defmodule ChordLab.Process.Manager do
  @moduledoc false

  def start_or_find(opts) do
    case Registry.lookup(ChordLab.Registry, opts[:id]) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        spec =
          case opts[:type] do
            :peer -> {ChordLab.Audio.Call.Peer, opts}
          end

        DynamicSupervisor.start_child(ChordLab.DynamicSupervisor, spec)
    end
  end

  def stop(id) do
    case Registry.lookup(ChordLab.Registry, id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(ChordLab.DynamicSupervisor, pid)

      [] ->
        {:error, :not_found}
    end
  end
end
