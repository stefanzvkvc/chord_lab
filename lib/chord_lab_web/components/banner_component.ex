defmodule ChordLabWeb.Components.BannerComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  attr :connection_lost, :boolean, required: true

  def render(assigns) do
    ~H"""
    <%= if @connection_lost do %>
      <div class="fixed top-0 left-0 w-full bg-red-600 text-white text-center py-2 z-50">
        <CoreComponents.icon name="hero-arrow-path" class="animate-spin h-6 w-6" />
        Connection lost, reconnecting...
      </div>
    <% end %>
    """
  end
end
