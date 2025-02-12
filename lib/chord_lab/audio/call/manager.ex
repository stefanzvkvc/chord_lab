defmodule ChordLab.Audio.Call.Manager do
  @moduledoc false

  def initiate_call(params) do
    call_id = params[:call_id]
    caller = params[:caller]
    callee = params[:callee]

    state = %{
      status: :initiated,
      initiated_at: DateTime.utc_now(),
      started_at: nil,
      ended_at: nil,
      caller: caller,
      callee: callee
    }

    Chord.set_context("call_id:#{call_id}", state)
  end
end
