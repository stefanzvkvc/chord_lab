defmodule ChordLabWeb.ChatLive do
  use Phoenix.LiveView

  alias ChordLabWeb.Presence
  alias ChordLab.Chat.Manager
  alias ChordLabWeb.CoreComponents

  alias ChordLabWeb.Components.{
    BannerComponent,
    SidebarComponent,
    ModalComponent,
    UsersComponent,
    ChatComponent
  }

  @presence_topic "presence"
  @public_channel_topic "public-channel"

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:user, %{username: nil})
      |> assign(:online_users, list_online_users())
      |> assign(:active_chat, %{id: nil, participant: nil})
      |> assign(:chats, %{})
      |> assign(:channels, [@public_channel_topic])
      |> assign(:unread_messages, %{})
      |> assign(:connection_lost, false)
      |> assign(
        :connection_lost_timer,
        Application.get_env(:chord_lab, :connection_lost_timer, 10_000)
      )

    if connected?(socket) do
      subscribe_to_presence_changes()
    end

    {:ok, socket}
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    %{chats: chats, online_users: online_users} = socket.assigns
    track_user_presence(username)
    subscribe_to_public_channel()

    online_users
    |> Enum.map(& &1.username)
    |> subscribe_to_private_chats(username)

    chats = Manager.sync(chats, @public_channel_topic, nil)

    {:noreply,
     assign(socket,
       user: %{username: username},
       chats: chats,
       active_chat: %{id: @public_channel_topic}
     )}
  end

  def handle_event("start_chat", %{"participant" => participant}, socket) do
    %{
      active_chat: %{id: active_chat_id},
      user: %{username: username},
      chats: chats,
      unread_messages: unread_messages
    } = socket.assigns

    chat_id = generate_chat_id(username, participant)

    if active_chat_id == chat_id do
      {:noreply, socket}
    else
      client_version = get_latest_chat_version(chats, chat_id)
      unread_messages = Map.delete(unread_messages, participant)
      chats = Manager.sync(chats, chat_id, client_version)

      socket =
        assign(socket,
          active_chat: %{id: chat_id, participant: participant},
          unread_messages: unread_messages,
          chats: chats
        )

      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{active_chat: %{id: chat_id}, user: %{username: sender}, chats: chats} =
      socket.assigns

    {chats, delta} = Manager.send_message(chats, chat_id, sender, message)
    socket = assign(socket, chats: chats)

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), chat_id, {:delta, delta})
    {:noreply, push_event(socket, "clear_input", %{})}
  end

  def handle_event("select_channel", %{"channel" => channel}, socket) do
    %{
      active_chat: %{id: chat_id},
      chats: chats,
      unread_messages: unread_messages
    } = socket.assigns

    if chat_id == channel do
      {:noreply, socket}
    else
      client_version = get_latest_chat_version(chats, channel)
      unread_messages = Map.delete(unread_messages, channel)
      chats = Manager.sync(chats, channel, client_version)

      socket =
        assign(socket,
          active_chat: %{id: channel, participant: nil},
          chats: chats,
          unread_messages: unread_messages
        )

      {:noreply, socket}
    end
  end

  def handle_event("leave_chat", _params, socket) do
    {:noreply, assign(socket, active_chat: %{id: @public_channel_topic, participant: nil})}
  end

  def handle_event("simulate_connection_loss", _params, socket) do
    %{user: %{username: username}, connection_lost_timer: timer} = socket.assigns
    socket = assign(socket, connection_lost: true)
    Presence.update(self(), @presence_topic, username, %{status: "offline"})

    {:noreply, push_event(socket, "simulate_connection_loss", %{timer: timer})}
  end

  def handle_event("simulate_connection_restore", _params, socket) do
    %{user: %{username: username}, chats: chats, active_chat: %{id: chat_id}} =
      socket.assigns

    client_version = get_latest_chat_version(chats, chat_id)
    chats = Manager.sync(chats, chat_id, client_version)

    Presence.update(self(), @presence_topic, username, %{status: "online"})
    {:noreply, assign(socket, connection_lost: false, chats: chats)}
  end

  def handle_info({:delta, _delta}, %{assigns: %{connection_lost: true}} = socket) do
    # Ignore delta updates when disconnected
    {:noreply, socket}
  end

  def handle_info({:delta, delta}, socket) do
    %{user: %{username: username}, chats: chats, active_chat: %{id: active_chat_id}} =
      socket.assigns

    case Manager.handle_delta(chats, active_chat_id, delta) do
      {:active, updated_chats} ->
        {:noreply, assign(socket, :chats, updated_chats)}

      {:inactive, chat_id, _messages} ->
        from = extract_chat_name(chat_id, username)
        unread_messages = update_unread_messages(socket.assigns.unread_messages, from)

        {:noreply, assign(socket, :unread_messages, unread_messages)}
    end
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    %{user: %{username: current_username}} = socket.assigns

    updated_online_users =
      Enum.reject(list_online_users(), fn %{username: username} ->
        username == current_username
      end)

    if current_username, do: subscribe_to_private_chats(Map.keys(joins), current_username)
    if current_username, do: unsubscribe_from_private_chats(Map.keys(leaves), current_username)

    {:noreply, assign(socket, online_users: updated_online_users)}
  end

  def terminate(_reason, _socket) do
    :ok
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col md:flex-row bg-elixir-phoenix-gradient text-white">
      <!-- Banner -->
      <BannerComponent.render connection_lost={@connection_lost} />
      <!-- Username Modal -->
      <ModalComponent.render show={@user[:username] == nil} />
      <!-- Sidebar -->
      <SidebarComponent.render heading="The Chat Lab">
        <:content>
          <!-- Channels List -->
          <.channels channels={@channels} unread_messages={@unread_messages} />
          <!-- Users List -->
          <UsersComponent.render current_user={@user.username} online_users={@online_users} unread_messages={@unread_messages} show_unread={true} service={:chat} />
        </:content>
      </SidebarComponent.render>
      <!-- Chat -->
      <ChatComponent.render heading={extract_chat_name(@active_chat[:id], @user[:username])} messages={@chats[@active_chat[:id]][:messages]} username={@user[:username]} />
    </div>
    """
  end

  attr(:channels, :map, required: true)
  attr(:unread_messages, :map, required: true)

  defp channels(assigns) do
    ~H"""
    <div class="mb-4">
      <ul class="space-y-2">
        <%= for channel_id <- @channels do %>
          <li
            phx-click="select_channel"
            phx-value-channel={channel_id}
            class="flex items-center justify-between p-4 rounded-lg bg-gray-800/40 hover:bg-gray-700/40 cursor-pointer transition"
          >
            <div class="flex items-center">
              <CoreComponents.icon name="hero-hashtag" class="w-6 h-6 text-white"/>
              <p class="font-semibold text-white ml-2">{channel_id}</p>
            </div>
            <%= if Map.get(@unread_messages, channel_id, 0) > 0 do %>
              <div class="flex items-center">
                <div class="text-xs bg-red-500 text-white rounded-full px-2 py-1">
                  <%= Map.get(@unread_messages, channel_id) %>
                </div>
              </div>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp get_latest_chat_version(chats, chat_id) do
    chats[chat_id][:version]
  end

  defp generate_chat_id(participant_1, participant_2) do
    [participant_1, participant_2]
    |> Enum.sort()
    |> Enum.join("-")
  end

  defp extract_chat_name(chat_id, username) do
    if chat_id do
      chat_id
      |> String.split("-")
      |> Enum.reject(&(&1 == username))
      |> case do
        [_, _] ->
          chat_id

        [from] ->
          from
      end
    end
  end

  defp update_unread_messages(unread_messages, from) do
    Map.update(unread_messages, from, 1, &(&1 + 1))
  end

  defp list_online_users() do
    @presence_topic
    |> Presence.list()
    |> Enum.map(fn {username, %{metas: [%{status: status} | _]}} ->
      %{username: username, status: status}
    end)
  end

  defp track_user_presence(username) do
    Presence.track(self(), @presence_topic, username, %{status: "online"})
  end

  defp subscribe_to_presence_changes() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @presence_topic)
  end

  defp subscribe_to_public_channel() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @public_channel_topic)
  end

  defp subscribe_to_private_chats(usernames, current_username) do
    Enum.each(usernames, fn username ->
      unless username == current_username do
        chat_id = generate_chat_id(username, current_username)
        Phoenix.PubSub.subscribe(ChordLab.PubSub, chat_id)
      end
    end)
  end

  defp unsubscribe_from_private_chats(usernames, current_username) do
    Enum.each(usernames, fn username ->
      unless username == current_username do
        chat_id = generate_chat_id(username, current_username)
        Phoenix.PubSub.unsubscribe(ChordLab.PubSub, chat_id)
      end
    end)
  end
end
