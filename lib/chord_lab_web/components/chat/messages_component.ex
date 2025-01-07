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
              <!-- Display sender's name if not me -->
              <%= if message.sender != @username do %>
                <p class="text-sm font-semibold mb-2 text-gray-100"><%= message.sender %></p>
              <% end %>
              <!-- Message content -->
              <p class="font-medium"><%= message.text %></p>
              <!-- Timestamp -->
              <p class="text-xs text-gray-300 mt-2"><%= format_timestamp(message.timestamp) %></p>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  def format_timestamp(timestamp) do
    timestamp
    |> DateTime.from_naive!("Etc/UTC")
    |> Timex.format!("{h12}:{m} {AM} - {YYYY}/{0M}/{0D}")
  end
end
