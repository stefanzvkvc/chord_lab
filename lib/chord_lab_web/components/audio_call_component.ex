defmodule ChordLabWeb.Components.AudioCallComponent do
  use Phoenix.Component
  alias ChordLabWeb.Components.AudioCall.{HeaderComponent, CallComponent}

  attr(:current_user, :string, required: true)
  attr(:active_call, :map, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col p-6 h-screen">
      <!-- Header -->
      <HeaderComponent.render />
      <!-- Grid -->
      <CallComponent.render current_user={@current_user} active_call={@active_call}/>
    </div>
    """
  end
end
