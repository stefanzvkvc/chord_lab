defmodule ChordLabWeb.Components.Chat.MessagesComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div id="messages-container" phx-hook="ScrollToLastMessage" class="flex-1 p-6 overflow-y-auto space-y-4 shadow-slate-500 bg-gray-800/40 rounded-lg">
      <%= if @messages do %>
        <%= for {_message_id, message} <- @messages do %>
          <div class={"flex " <> if message.sender == @username, do: "justify-end", else: "justify-start"}>
            <div
              class="max-w-md p-4 rounded-lg shadow-md"
              style={
                if message.sender == @username,
                do: "background-color: #6C63FF; color: white;",
                else: "background-color: #FFAA00; color: white;"
              }>
              <p class="font-medium"><%= message.text %></p>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
