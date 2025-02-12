defmodule ChordLabWeb.Components.Sidebar.HeaderComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  attr :heading, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6 h-8">
      <!-- Heading -->
      <h1 class="text-xl font-bold">{@heading}</h1>
      <!-- Home Button -->
      <a href="/" class="p-2 bg-gray-800/40 hover:bg-gray-700/40 rounded-full transition">
        <CoreComponents.icon name="hero-home" class="w-6 h-6 text-white"/>
      </a>
    </div>
    """
  end
end
