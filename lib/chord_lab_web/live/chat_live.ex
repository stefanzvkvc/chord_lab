defmodule ChordLabWeb.ChatLive do
  use Phoenix.LiveView

  alias ChordLabWeb.Presence
  alias ChordLab.Context.Manager

  alias ChordLabWeb.Components.{
    SidebarComponent,
    ModalComponent,
    Chat.HeaderComponent,
    Chat.MessagesComponent,
    Chat.MessageInputComponent
  }

  @presence_topic "presence"
  @public_channel_topic "public-channel"

  def mount(_params, _session, socket) do
    socket =
      socket
      # sanitize usernames to avoid unexpected topic naming issues
      |> assign(:username, nil)
      |> assign(:online_users, list_online_users())
      |> assign(:active_chat, nil)
      |> assign(:active_participant, nil)
      |> assign(:chats, %{})
      |> assign(:unread_messages, %{})

    if connected?(socket) do
      subscribe_to_presence_changes()
    end

    {:ok, socket}
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    %{chats: chats} = socket.assigns
    track_user_presence(username)
    subscribe_to_public_channel()
    subscribe_to_private_chats(username, list_online_users())
    chats = Manager.sync(chats, @public_channel_topic, nil)

    {:noreply,
     assign(socket,
       username: username,
       chats: chats,
       active_chat: @public_channel_topic
     )}
  end

  def handle_event("start_chat", %{"participant" => participant}, socket) do
    %{
      active_chat: active_chat,
      username: username,
      chats: chats,
      unread_messages: unread_messages
    } = socket.assigns

    chat_id = generate_chat_id(username, participant)

    if active_chat == chat_id do
      {:noreply, socket}
    else
      client_version = get_latest_chat_version(chats, chat_id)
      unread_messages = Map.delete(unread_messages, participant)
      chats = Manager.sync(chats, chat_id, client_version)

      socket =
        assign(socket,
          active_chat: chat_id,
          active_participant: participant,
          unread_messages: unread_messages,
          chats: chats
        )

      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{active_chat: chat_id, username: sender, chats: chats} =
      socket.assigns

    {chats, delta} = Manager.send_message(chats, chat_id, sender, message)
    socket = assign(socket, chats: chats)

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), chat_id, {:delta, delta})
    {:noreply, socket}
  end

  def handle_event("select_channel", %{"channel" => channel}, socket) do
    %{
      active_chat: active_chat,
      chats: chats,
      unread_messages: unread_messages
    } = socket.assigns

    if active_chat == channel do
      {:noreply, socket}
    else
      client_version = get_latest_chat_version(chats, channel)
      unread_messages = Map.delete(unread_messages, channel)
      chats = Manager.sync(chats, channel, client_version)

      socket =
        assign(socket,
          active_chat: channel,
          chats: chats,
          unread_messages: unread_messages,
          active_participant: nil
        )

      {:noreply, socket}
    end
  end

  def handle_event("leave_chat", _params, socket) do
    socket =
      socket
      |> assign(active_chat: @public_channel_topic)
      |> assign(active_participant: nil)

    {:noreply, socket}
  end

  def handle_event("simulate_connection_loss", _params, socket) do
    {:noreply, push_event(socket, "simulate_connection_loss", %{})}
  end

  def handle_info({:delta, delta}, socket) do
    %{chats: chats, active_chat: active_chat} = socket.assigns

    case Manager.handle_delta(chats, active_chat, delta) do
      {:active, updated_chats} ->
        {:noreply, assign(socket, :chats, updated_chats)}

      {:inactive, chat_id, messages} ->
        from = extract_chat_name(chat_id, socket.assigns.username)
        unread_messages = update_unread_messages(socket.assigns.unread_messages, from)

        {:noreply, assign(socket, :unread_messages, unread_messages)}
    end
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    %{username: username} = socket.assigns

    joins = Map.keys(diff.joins)
    leaves = Map.keys(diff.leaves)

    if username do
      joins = Enum.reject(joins, &(&1 == username))
      leaves = Enum.reject(leaves, &(&1 == username))
      subscribe_to_private_chats(username, joins)
      unsubscribe_from_private_chats(username, leaves)
    end

    updated_online_users =
      socket.assigns.online_users
      |> Enum.concat(joins)
      |> Enum.reject(&(&1 in leaves))
      |> Enum.uniq()
      |> Enum.reject(&(&1 == username))

    {:noreply, assign(socket, online_users: updated_online_users)}
  end

  def terminate(_reason, socket) do
    Presence.untrack(self(), @presence_topic, socket.assigns.username)
    :ok
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col md:flex-row bg-elixir-phoenix-gradient text-white">
      <!-- Username Modal -->
      <ModalComponent.render show_username_modal={@username == nil} />
      <!-- Sidebar -->
      <SidebarComponent.render header_title="The Chat Lab" online_users={@online_users} unread_messages={@unread_messages} />
      <!-- Chat Window -->
      <div class="flex-1 flex flex-col p-6 h-screen">
        <!-- Header -->
        <HeaderComponent.render header={extract_chat_name(@active_chat, @username)}/>
        <!-- Chat Messages -->
        <MessagesComponent.render messages={@chats[@active_chat][:messages]} username={@username} />
        <!-- Message Input -->
        <MessageInputComponent.render />
      </div>
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
    |> Map.keys()
  end

  defp track_user_presence(username) do
    Presence.track(self(), @presence_topic, username, %{})
  end

  defp subscribe_to_presence_changes() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @presence_topic)
  end

  defp subscribe_to_public_channel() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @public_channel_topic)
  end

  defp subscribe_to_private_chats(username, users) do
    Enum.each(users, fn user ->
      chat_id = generate_chat_id(username, user)
      Phoenix.PubSub.subscribe(ChordLab.PubSub, chat_id)
    end)
  end

  defp unsubscribe_from_private_chats(username, users) do
    Enum.each(users, fn user ->
      chat_id = generate_chat_id(username, user)
      Phoenix.PubSub.unsubscribe(ChordLab.PubSub, chat_id)
    end)
  end
end
