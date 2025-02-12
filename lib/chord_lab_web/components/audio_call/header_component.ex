defmodule ChordLabWeb.Components.AudioCall.HeaderComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-16 h-8">
      <h2 class="text-xl font-bold">Join the audio call!</h2>
      <div class="flex items-center space-x-4">
      <button id="connection-simulator" phx-hook="ConnectionSimulator" phx-click="simulate_connection_loss" title="Simulate internet connection loss" class="p-2 bg-red-500 hover:bg-red-400 rounded-full transition">
        <CoreComponents.icon name="hero-signal-slash" class="w-6 h-6 text-white"/>
      </button>
      </div>
    </div>
    """
  end
end
