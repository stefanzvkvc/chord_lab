defmodule ChordLabWeb.Components.AudioCall.CallComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  attr(:current_user, :string, required: true)
  attr(:active_call, :map, required: true)

  def render(assigns) do
    ~H"""
    <div class="h-full" id="audio-call-container" phx-hook="AudioCallChannel">
      <%= if @active_call.call_id do %>
        <div class="flex flex-col h-full p-6 space-y-4 shadow-slate-500 bg-gray-800/40 rounded-lg">
          <div class="flex items-center justify-center h-full">
            <%= case @active_call.status do %>
              <% "ringing" -> %>
                <CoreComponents.icon name="hero-phone" class="w-28 h-28 text-white animate-wiggle" />
              <% "connected" -> %>
                <CoreComponents.icon name="hero-phone" class="w-28 h-28 text-white animate-pulse" />
                <audio id="remote-audio" autoplay controls/>
            <% end %>
          </div>
          <div class="h-14 mt-4 p-2 flex items-center justify-center">
            <%= if @active_call.caller.username == @current_user or (@active_call.status == "connected" and @active_call.callee.username == @current_user) do %>
              <div class="rounded-full p-2 cursor-pointer shadow-slate-500 bg-gray-800/40 w-min" phx-click="cancel_audio_call">
                <CoreComponents.icon name="hero-phone" class="w-6 h-6 bg-red-500" />
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
