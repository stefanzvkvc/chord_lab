defmodule ChordLabWeb.Components.UsersComponent do
  use Phoenix.Component
  alias ChordLabWeb.CoreComponents

  attr(:online_users, :list, required: true)
  attr(:unread_messages, :map, default: %{})
  attr(:show_unread, :boolean, default: false)
  attr(:service, :atom, default: nil)
  attr(:current_user, :string, required: true)
  attr(:call_id, :string, required: false)

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-medium mb-4">Online Users</h3>
      <% filtered_online_users = Enum.filter(@online_users, &(&1.username != @current_user)) %>
      <ul class="space-y-4">
        <%= if Enum.empty?(filtered_online_users) do %>
          <!-- No Online Users Placeholder -->
          <li class="flex flex-col items-center justify-center bg-gray-800/40 rounded-lg p-6 text-center text-gray-400">
            <CoreComponents.icon name="hero-users" class="w-12 h-12 text-gray-400"/>
            <p class="font-semibold">No users are online</p>
            <p class="text-sm">Check back later!</p>
          </li>
        <% else %>
          <%= for online_user <- filtered_online_users do %>
            <li class="flex items-center justify-between p-4 rounded-lg hover:bg-gray-700/40 transition bg-gray-800/40">
              <div class="flex items-center">
                <div class={["w-12 h-12 rounded-full flex items-center justify-center text-xl text-white font-bold",
                    online_user.status == "online" && "bg-purple-600 border-4 border-green-500",
                    online_user.status == "busy" && "bg-purple-600 border-4 border-red-500",
                    online_user.status == "offline" && "bg-purple-600 border-4 border-gray-500"]}>
                  <%= String.slice(online_user.username, 0, 2) %>
                </div>
                <div class="ml-4">
                  <p class="font-semibold text-white"><%= online_user.username %></p>
                  <p class="text-sm text-gray-400"><%= online_user.status %></p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <!-- Unread Messages -->
                <%= if @show_unread && Map.get(@unread_messages, online_user.username, 0) > 0 do %>
                  <div class="text-xs bg-red-500 text-white rounded-full px-2 py-1">
                  <%= Map.get(@unread_messages, online_user.username) %>
                  </div>
                <% end %>
                <!-- Service Button -->
                <%= case @service do %>
                  <% :chat -> %>
                    <div class="rounded-full ml-2 p-2 cursor-pointer shadow-slate-500 bg-gray-800/40 w-min" phx-click="start_chat" phx-value-participant={online_user.username}>
                      <CoreComponents.icon name="hero-paper-airplane" class="w-6 h-6 text-white" />
                    </div>
                  <% :audio_call -> %>
                    <%= case online_user.status do %>
                      <% "online" -> %>
                        <div class="rounded-full ml-2 p-2 cursor-pointer shadow-slate-500 bg-gray-800/40 w-min" phx-click="start_audio_call" phx-value-callee={online_user.username}>
                          <CoreComponents.icon name="hero-phone" class="w-6 h-6 text-white" />
                        </div>
                      <% "busy" -> %>
                        <%= if online_user.call.role == "caller" && online_user.call.call_id == @call_id && online_user.call.status == "ringing" do %>
                          <div class="rounded-full ml-2 p-2 cursor-pointer shadow-slate-500 bg-gray-800/40 w-min" phx-click="accept_audio_call">
                            <CoreComponents.icon name="hero-phone" class="w-6 h-6 bg-green-500" />
                          </div>
                          <div class="rounded-full ml-2 p-2 cursor-pointer shadow-slate-500 bg-gray-800/40 w-min" phx-click="reject_audio_call">
                            <CoreComponents.icon name="hero-phone" class="w-6 h-6 bg-red-500" />
                          </div>
                        <% end %>
                    <% end %>
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
