defmodule ChordLabWeb.Components.SidebarComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="md:w-1/3 w-full p-6 flex flex-col">
      <div class="flex items-center justify-between mb-6 h-8">
        <h1 class="text-xl font-bold">{@header_title}</h1>
        <!-- Home Button -->
        <a href="/" class="p-2 bg-gray-800/40 hover:bg-gray-700/40 rounded-full transition">
          <CoreComponents.icon name="hero-home" class="w-6 h-6 text-white"/>
        </a>
      </div>

      <!-- Channels Section -->
      <div class="mb-4">
        <h2 class="text-lg font-semibold mb-2">Channels</h2>
        <ul class="space-y-2">
          <li
            phx-click="select_channel"
            phx-value-channel="public-channel"
            class={["flex items-center justify-between p-4 rounded-lg bg-gray-800/40 hover:bg-gray-700/40 cursor-pointer transition"]}
          >
            <div class="flex items-center">
              <CoreComponents.icon name="hero-hashtag" class="w-6 h-6 text-white"/>
              <p class="font-semibold text-white ml-2">public-chat</p>
            </div>
            <%= if Map.get(@unread_messages, "public-channel", 0) > 0 do %>
              <div class="flex items-center">
                <div class="text-xs bg-red-500 text-white rounded-full px-2 py-1">
                  <%= Map.get(@unread_messages, "public-channel") %>
                </div>
              </div>
            <% end %>
          </li>
          <!-- Add more channels dynamically in the future -->
        </ul>
      </div>

      <!-- Header for Online User List -->
      <div class="mb-4">
        <h3 class="text-lg font-medium">Online Users</h3>
      </div>

      <!-- User List -->
      <ul class="space-y-4">
        <%= if Enum.empty?(@online_users) do %>
          <!-- No Online Users Placeholder -->
          <li class="flex flex-col items-center justify-center bg-gray-800/40 rounded-lg p-6 text-center text-gray-400">
            <CoreComponents.icon name="hero-users" class="w-12 h-12 text-gray-400"/>
            <p class="font-semibold">No users are online</p>
            <p class="text-sm">Check back later to start chatting!</p>
          </li>
        <% else %>
          <%= for online_user <- @online_users do %>
            <li
              phx-click="start_chat"
              phx-value-participant={online_user}
              class={[
                "flex items-center justify-between p-4 rounded-lg hover:bg-gray-700/40 transition cursor-pointer bg-gray-800/40"
              ]}
            >
              <div class="flex items-center">
                <div class="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center text-xl text-white font-bold">
                  <%= String.slice(online_user, 0, 2) %>
                </div>
                <div class="ml-4">
                  <p class="font-semibold text-white"><%= online_user %></p>
                  <p class="text-sm text-gray-400">Online</p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-green-500 rounded-full"></div>
                <%= if Map.get(@unread_messages, online_user, 0) > 0 do %>
                  <div class="text-xs bg-red-500 text-white rounded-full px-2 py-1">
                    <%= Map.get(@unread_messages, online_user) %>
                  </div>
                <% end %>
              </div>
            </li>
          <% end %>
        <% end %>
      </ul>
    </div>
    """
  end
end
