defmodule ChordLabWeb.AudioCallLive do
  use Phoenix.LiveView
  alias ChordLabWeb.Presence

  alias ChordLabWeb.Components.{
    BannerComponent,
    SidebarComponent,
    ModalComponent,
    UsersComponent,
    AudioCallComponent
  }

  @presence_topic "presence"
  @audio_call_topic "audio_call:lobby"

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:user, %{username: nil})
      |> assign(:online_users, list_online_users())
      |> assign(:active_call, %{
        call_id: nil,
        caller: %{username: nil},
        callee: %{username: nil},
        status: nil
      })
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
    %{online_users: online_users} = socket.assigns
    track_user_presence(username)

    online_users
    |> Enum.map(& &1.username)
    |> subscribe_to_calls(username)

    socket = assign(socket, user: %{username: username})
    {:noreply, push_event(socket, "join", %{topic: @audio_call_topic, username: username})}
  end

  def handle_event("start_audio_call", %{"callee" => callee}, socket) do
    %{user: %{username: username}} = socket.assigns
    call_id = generate_call_id(username, callee)
    payload = %{call_id: call_id, caller: username, callee: callee}
    {:noreply, push_event(socket, "call", payload)}
  end

  def handle_event("accept_audio_call", _params, socket) do
    %{active_call: %{call_id: call_id}} = socket.assigns
    {:noreply, push_event(socket, "accept", %{call_id: call_id})}
  end

  def handle_event("accepted", _params, socket) do
    %{user: %{username: username}, active_call: %{call_id: call_id}} = socket.assigns

    socket = update_active_call(socket, "connected")

    Presence.update(self(), @presence_topic, username, %{
      status: "busy",
      call: %{call_id: call_id, role: "callee", status: "connected"}
    })

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), call_id, :accepted)

    {:noreply, socket}
  end

  def handle_event("ringing", call, socket) do
    %{user: %{username: username}} = socket.assigns
    %{"call_id" => call_id} = call
    socket = set_active_call(socket, call, "ringing")

    Presence.update(self(), @presence_topic, username, %{
      status: "busy",
      call: %{call_id: call_id, role: "caller", status: "ringing"}
    })

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), call_id, {:ringing, call})
    {:noreply, socket}
  end

  def handle_event("reject_audio_call", _params, socket) do
    %{active_call: %{call_id: call_id}} = socket.assigns
    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), call_id, :reject)
    {:noreply, socket}
  end

  def handle_event("rejected", _params, socket) do
    %{user: %{username: username}, active_call: %{call_id: call_id}} = socket.assigns
    socket = reset_active_call(socket)

    Presence.update(self(), @presence_topic, username, %{
      status: "online",
      call: %{role: nil, call_id: nil, status: nil}
    })

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), call_id, :rejected)
    {:noreply, socket}
  end

  def handle_event("cancel_audio_call", _params, socket) do
    {:noreply, push_event(socket, "cancel", %{})}
  end

  def handle_event("canceled", _params, socket) do
    %{user: %{username: username}, active_call: %{call_id: call_id}} = socket.assigns
    socket = reset_active_call(socket)

    Presence.update(self(), @presence_topic, username, %{
      status: "online",
      call: %{role: nil, call_id: nil, status: nil}
    })

    Phoenix.PubSub.broadcast_from(ChordLab.PubSub, self(), call_id, :canceled)
    {:noreply, socket}
  end

  def handle_info({:ringing, call}, socket) do
    %{user: %{username: username}} = socket.assigns
    %{"call_id" => call_id} = call
    socket = set_active_call(socket, call, "ringing")

    Presence.update(self(), @presence_topic, username, %{
      status: "busy",
      call: %{call_id: call_id, role: "callee", status: "ringing"}
    })

    {:noreply, socket}
  end

  def handle_info(:reject, socket) do
    {:noreply, push_event(socket, "reject", %{})}
  end

  def handle_info(:rejected, socket) do
    %{user: %{username: username}} = socket.assigns
    socket = reset_active_call(socket)

    Presence.update(self(), @presence_topic, username, %{
      status: "online",
      call: %{role: nil, call_id: nil, status: nil}
    })

    {:noreply, socket}
  end

  def handle_info(:canceled, socket) do
    %{user: %{username: username}} = socket.assigns
    socket = reset_active_call(socket)

    Presence.update(self(), @presence_topic, username, %{
      status: "online",
      call: %{role: nil, call_id: nil, status: nil}
    })

    ## TODO: push event to client to stop access to mic
    {:noreply, socket}
  end

  def handle_info(:accepted, socket) do
    %{user: %{username: username}, active_call: %{call_id: call_id}} = socket.assigns

    socket = update_active_call(socket, "connected")

    Presence.update(self(), @presence_topic, username, %{
      status: "busy",
      call: %{call_id: call_id, role: "caller", status: "connected"}
    })

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    %{user: %{username: current_username}} = socket.assigns

    cond do
      is_binary(current_username) and map_size(joins) > 0 and map_size(leaves) == 0 ->
        subscribe_to_calls(Map.keys(joins), current_username)

      is_binary(current_username) and map_size(joins) == 0 and map_size(leaves) > 0 ->
        unsubscribe_from_calls(Map.keys(leaves), current_username)

      true ->
        :ok
    end

    {:noreply, assign(socket, online_users: list_online_users())}
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
      <ModalComponent.render show={@user.username == nil} />
      <!-- Sidebar -->
      <SidebarComponent.render heading="The Audio Lab">
        <:content>
          <!-- Users List -->
          <UsersComponent.render current_user={@user.username} online_users={@online_users} service={:audio_call} call_id={@active_call.call_id} />
          <!-- Call history List -->
          <ChordLabWeb.Components.AudioCall.HistoryComponent.render/>
        </:content>
      </SidebarComponent.render>
      <!-- Audio Call -->
      <AudioCallComponent.render current_user={@user.username} active_call={@active_call}/>
    </div>
    """
  end

  defp list_online_users() do
    @presence_topic
    |> Presence.list()
    |> Enum.map(fn {username, %{metas: [meta | _]}} ->
      Map.put(meta, :username, username)
    end)
  end

  defp subscribe_to_presence_changes() do
    Phoenix.PubSub.subscribe(ChordLab.PubSub, @presence_topic)
  end

  defp subscribe_to_calls(usernames, current_username) do
    Enum.each(usernames, fn username ->
      unless username == current_username do
        call_id = generate_call_id(username, current_username)
        Phoenix.PubSub.subscribe(ChordLab.PubSub, call_id)
      end
    end)
  end

  defp unsubscribe_from_calls(usernames, current_username) do
    Enum.each(usernames, fn username ->
      unless username == current_username do
        call_id = generate_call_id(username, current_username)
        Phoenix.PubSub.unsubscribe(ChordLab.PubSub, call_id)
      end
    end)
  end

  defp track_user_presence(username) do
    Presence.track(self(), @presence_topic, username, %{
      status: "online",
      call: %{role: nil, call_id: nil, status: nil}
    })
  end

  defp generate_call_id(participant_1, participant_2) do
    [participant_1, participant_2]
    |> Enum.sort()
    |> Enum.join("-")
  end

  defp update_active_call(socket, status) do
    %{active_call: call} = socket.assigns
    set_active_call(socket, call, status)
  end

  defp set_active_call(socket, call, status) do
    assign(socket,
      active_call: %{
        call_id: call["call_id"] || call.call_id,
        caller: %{username: call["caller"] || call.caller.username},
        callee: %{username: call["callee"] || call.callee.username},
        status: status
      }
    )
  end

  defp reset_active_call(socket) do
    assign(socket,
      active_call: %{
        call_id: nil,
        caller: %{username: nil},
        callee: %{username: nil},
        status: nil
      }
    )
  end
end
