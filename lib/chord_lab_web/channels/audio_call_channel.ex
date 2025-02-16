defmodule ChordLabWeb.AudioCallChannel do
  use ChordLabWeb, :channel

  @impl true
  def join("audio_call:lobby", payload, socket) do
    send(self(), {:after_join, payload})
    {:ok, socket}
  end

  @impl true
  def handle_in("create_audio_room", payload, socket) do
    %{"call_id" => call_id, "caller" => caller, "callee" => callee} = payload
    %{requests: requests, peer_pid: peer_pid} = socket.assigns
    requests = Map.put(requests, :create_audio_room, socket_ref(socket))

    socket =
      assign(socket,
        requests: requests,
        call: %{call_id: call_id, caller: caller, callee: callee}
      )

    Task.start(fn -> send(peer_pid, {:create_audio_room, call_id}) end)

    {:noreply, socket}
  end

  @impl true
  def handle_in("join_audio_room", %{"call_id" => call_id}, socket) do
    %{requests: requests, peer_pid: peer_pid} = socket.assigns
    requests = Map.put(requests, :join_audio_room, socket_ref(socket))
    socket = assign(socket, :requests, requests)
    Task.start(fn -> send(peer_pid, {:join_audio_room, call_id}) end)

    {:noreply, socket}
  end

  @impl true
  def handle_in("reject", _payload, socket) do
    %{requests: requests, peer_pid: peer_pid} = socket.assigns
    requests = Map.put(requests, :destroy_audio_room, socket_ref(socket))
    socket = assign(socket, :requests, requests)
    Task.start(fn -> send(peer_pid, :destroy_audio_room) end)

    {:noreply, socket}
  end

  @impl true
  def handle_in("cancel", _payload, socket) do
    %{requests: requests, peer_pid: peer_pid} = socket.assigns
    requests = Map.put(requests, :destroy_audio_room, socket_ref(socket))
    socket = assign(socket, :requests, requests)
    Task.start(fn -> send(peer_pid, :destroy_audio_room) end)

    {:noreply, socket}
  end

  @impl true
  def handle_in("ice_candidate", %{"candidate" => %{"candidate" => candidate}}, socket) do
    %{peer_pid: pid} = socket.assigns
    send(pid, {:ice_candidate, candidate})
    {:reply, {:ok, %{}}, socket}
  end

  @impl true
  def handle_in("sdp_offer", %{"jsep" => jsep}, socket) do
    %{peer_pid: pid} = socket.assigns
    send(pid, {:sdp_offer, jsep})
    {:reply, {:ok, %{}}, socket}
  end

  @impl true
  def handle_info({:after_join, payload}, socket) do
    %{"username" => username} = payload
    opts = [id: username, type: :peer, channel_pid: self()]
    {:ok, peer_pid} = ChordLab.Process.Manager.start_or_find(opts)
    socket = assign(socket, username: username, peer_pid: peer_pid, call: %{}, requests: %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info(:audio_room_created, socket) do
    %{requests: requests} = socket.assigns
    {ref, new_requests} = pop_in(requests, [:create_audio_room])
    reply(ref, {:ok, %{}})
    {:noreply, assign(socket, requests: new_requests)}
  end

  @impl true
  def handle_info(:audio_room_joined, socket) do
    %{requests: requests, call: call} = socket.assigns
    {ref, new_requests} = pop_in(requests, [:join_audio_room])
    reply(ref, {:ok, call})
    {:noreply, assign(socket, requests: new_requests)}
  end

  @impl true
  def handle_info(:audio_room_destroyed, socket) do
    %{requests: requests} = socket.assigns
    {ref, new_requests} = pop_in(requests, [:destroy_audio_room])
    reply(ref, {:ok, %{}})
    {:noreply, assign(socket, requests: new_requests, call: %{})}
  end

  @impl true
  def handle_info({:sdp_answer, jsep}, socket) do
    push(socket, "sdp_answer", %{jsep: jsep})
    {:noreply, socket}
  end
end
