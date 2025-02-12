defmodule ChordLabWeb.Components.ChatComponent do
  use Phoenix.Component
  alias ChordLabWeb.Components.Chat.{HeaderComponent, MessagesComponent, MessageInputComponent}

  attr :heading, :string, required: true
  attr :username, :string, required: true
  attr :messages, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col p-6 h-screen">
      <!-- Header -->
      <HeaderComponent.render heading={@heading} />

      <!-- Chat Messages -->
      <MessagesComponent.render messages={@messages} username={@username} />

      <!-- Message Input -->
      <MessageInputComponent.render />
    </div>
    """
  end
end
