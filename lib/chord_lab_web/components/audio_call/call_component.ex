defmodule ChordLabWeb.Components.AudioCall.CallComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  attr(:current_user, :string, required: true)
  attr(:call_id, :string, required: true)
  attr(:caller, :string, required: true)
  attr(:callee, :string, required: true)
  attr(:status, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="h-full" id="audio-call-container" phx-hook="AudioCallChannel">
      <%= if @call_id do %>
        <div class="flex flex-col h-full p-6 space-y-4 shadow-slate-500 bg-gray-800/40 rounded-lg">
          <div class="flex items-center justify-center h-full">
            <%= if @status do %>
              <%= case @status do %>
                <% "ringing" -> %>
                  <CoreComponents.icon name="hero-phone" class="w-28 h-28 text-white animate-wiggle" />
                <% "connected" -> %>
                  <audio id="local-audio" autoplay playsinline>
                    <CoreComponents.icon name="hero-phone" class="w-28 h-28 text-white animate-pulse" />
                  </audio>
              <% end %>
            <% end %>
          </div>
          <div class="h-14 mt-4 p-2 flex items-center justify-center">
            <%= if @caller == @current_user or (@status == "connected" and @callee == @current_user) do %>
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
