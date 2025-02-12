defmodule ChordLabWeb.Components.SidebarComponent do
  use Phoenix.Component
  alias ChordLabWeb.Components.Sidebar.HeaderComponent

  attr(:heading, :string, required: true)

  # Slots for dynamic content (e.g., chat lobby, video lobby, etc.)
  slot(:content, required: false)

  def render(assigns) do
    ~H"""
    <div class="md:w-1/3 w-full p-6 flex flex-col">
      <!-- Header -->
      <HeaderComponent.render heading={@heading} />

      <!-- Dynamic Content -->
      <div class="flex-1 overflow-y-auto">
        <%= render_slot(@content) %>
      </div>
    </div>
    """
  end
end
