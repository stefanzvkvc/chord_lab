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
      |> assign(:online_users, list_online_users())
      |> assign(:username, nil)
      |> assign(:participant, nil)
      |> assign(:active_conversation, nil)
      |> assign(:conversations, %{})
      |> assign(:unread_messages, %{})

    if connected?(socket) do
      subscribe_to_presence_changes()
    end

    {:ok, socket}
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    %{conversations: conversations} = socket.assigns
    track_user_presence(username)
    subscribe_to_public_conversation()
    subscribe_to_private_conversations(username, list_online_users())
    conversations = Manager.sync(conversations, @public_channel_topic, nil)

    {:noreply,
     assign(socket,
       username: username,
       conversations: conversations,
       active_conversation: @public_channel_topic
     )}
  end

  def handle_event("start_chat", %{"participant" => participant}, socket) do
    %{
      active_conversation: active_conversation,
      username: username,
      conversations: conversations,
      unread_messages: unread_messages
    } = socket.assigns

    conversation_id = generate_conversation_id(username, participant)

    if active_conversation == conversation_id do
      {:noreply, socket}
    else
      client_version = get_latest_conversation_version(conversations, conversation_id)
      unread_messages = Map.delete(unread_messages, participant)
      conversations = Manager.sync(conversations, conversation_id, client_version)

      socket =
        assign(socket,
          active_conversation: conversation_id,
          participant: participant,
          unread_messages: unread_messages,
          conversations: conversations
        )

      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{active_conversation: conversation_id, username: sender, conversations: conversations} =
      socket.assigns

    {conversations, delta} = Manager.send_message(conversations, conversation_id, sender, message)
    socket = assign(socket, conversations: conversations)

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), conversation_id, {:delta, delta})
    {:noreply, socket}
  end

  def handle_event("select_channel", %{"channel" => channel}, socket) do
    %{
      active_conversation: active_conversation,
      conversations: conversations,
      unread_messages: unread_messages
    } = socket.assigns

    if active_conversation == channel do
      {:noreply, socket}
    else
      client_version = get_latest_conversation_version(conversations, channel)
      unread_messages = Map.delete(unread_messages, channel)
      conversations = Manager.sync(conversations, channel, client_version)

      socket =
        assign(socket,
          active_conversation: channel,
          conversations: conversations,
          unread_messages: unread_messages,
          participant: nil
        )

      {:noreply, socket}
    end
  end

  def handle_event("leave_chat", _params, socket) do
    socket =
      socket
      |> assign(active_conversation: @public_channel_topic)
      |> assign(participant: nil)

    {:noreply, socket}
  end

  def handle_event("simulate_connection_loss", _params, socket) do
    {:noreply, push_event(socket, "simulate_connection_loss", %{})}
  end

  def handle_info({:delta, delta}, socket) do
    %{conversations: conversations, active_conversation: active_conversation} = socket.assigns

    case Manager.handle_delta(conversations, active_conversation, delta) do
      {:active, updated_conversations} ->
        {:noreply, assign(socket, :conversations, updated_conversations)}

      {:inactive, conversation_id, messages} ->
        from = extract_conversation_name(conversation_id, socket.assigns.username)
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
      subscribe_to_private_conversations(username, joins)
      unsubscribe_from_private_conversations(username, leaves)
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
        <HeaderComponent.render header={extract_conversation_name(@active_conversation, @username)} participant={@participant} channel/>
        <!-- Chat Messages -->
        <MessagesComponent.render messages={@conversations[@active_conversation][:messages]} username={@username} />
        <!-- Message Input -->
        <MessageInputComponent.render />
      </div>
    </div>
    """
  end

  defp get_latest_conversation_version(conversations, conversation_id) do
    conversations[conversation_id][:version]
  end

  defp generate_conversation_id(participant_1, participant_2) do
    [participant_1, participant_2]
    |> Enum.sort()
    |> Enum.join("-")
  end

  defp extract_conversation_name(conversation_id, username) do
    if conversation_id do
      conversation_id
      |> String.split("-")
      |> Enum.reject(&(&1 == username))
      |> case do
        [_, _] ->
          conversation_id

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

  defp subscribe_to_public_conversation() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @public_channel_topic)
  end

  defp subscribe_to_private_conversations(username, users) do
    Enum.each(users, fn user ->
      conversation_id = generate_conversation_id(username, user)
      Phoenix.PubSub.subscribe(ChordLab.PubSub, conversation_id)
    end)
  end

  defp unsubscribe_from_private_conversations(username, users) do
    Enum.each(users, fn user ->
      conversation_id = generate_conversation_id(username, user)
      Phoenix.PubSub.unsubscribe(ChordLab.PubSub, conversation_id)
    end)
  end
end
