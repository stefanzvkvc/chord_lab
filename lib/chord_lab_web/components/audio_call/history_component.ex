defmodule ChordLabWeb.Components.AudioCall.HistoryComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-medium mb-4">Recents</h3>
      <ul class="space-y-4">
        <!-- No recents calls -->
          <li class="flex flex-col items-center justify-center bg-gray-800/40 rounded-lg p-6 text-center text-gray-400">
            <CoreComponents.icon name="hero-clock" class="w-12 h-12 text-gray-400"/>
            <p class="font-semibold">No recent calls</p>
            <p class="text-sm">A record of your call will appear here.</p>
          </li>
      </ul>
    </div>
    """
  end
end
