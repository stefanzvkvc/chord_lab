defmodule ChordLab.Audio.Call.Peer do
  @moduledoc false

  use GenServer
  require Logger
  alias ChordLab.Janus.Client
  @plugin "janus.plugin.audiobridge"
  @keepalive_interval 60_000
  @max_room_id 2_147_483_647

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(args[:id]))
  end

  def init(args) do
    state = %{
      id: args[:id],
      channel_pid: args[:channel_pid],
      janus: %{
        requests: %{},
        events: %{},
        client_pid: nil,
        session_id: nil,
        handle_id: nil,
        room_id: nil
      }
    }

    {:ok, state, {:continue, :start_janus_client}}
  end

  def handle_continue(:start_janus_client, state) do
    case Client.start_link(%{pid: self()}) do
      {:ok, client_pid} ->
        state = put_in(state[:janus][:client_pid], client_pid)
        {:noreply, state, {:continue, :create_session}}

      {:error, _reason} ->
        {:stop, :normal, state}
    end
  end

  def handle_continue(:create_session, state) do
    %{janus: %{client_pid: client_pid}} = state
    request_id = create_request_id()
    request = %{janus: :create, transaction: request_id}

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :create_session)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_continue(:attach_plugin, state) do
    %{janus: %{client_pid: client_pid, session_id: session_id}} = state
    request_id = create_request_id()
    request = %{janus: :attach, session_id: session_id, plugin: @plugin, transaction: request_id}

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :attach_plugin)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_continue(:attached, state) do
    # Start with keepalive messages
    Process.send_after(self(), :keepalive, @keepalive_interval)
    {:noreply, state}
  end

  def handle_continue(:audio_room_created = response, state) do
    %{channel_pid: channel_pid} = state
    send(channel_pid, response)
    {:noreply, state}
  end

  def handle_continue(:audio_room_joined = response, state) do
    %{channel_pid: channel_pid, janus: %{room_id: room_id}} = state
    send(channel_pid, {response, room_id})
    {:noreply, state}
  end

  def handle_continue(:audio_room_destroyed = response, state) do
    %{channel_pid: channel_pid} = state
    send(channel_pid, response)
    {:noreply, state}
  end

  def handle_continue(:keepalive, state) do
    Process.send_after(self(), :keepalive, @keepalive_interval)
    {:noreply, state}
  end

  def handle_info(:keepalive, state) do
    %{janus: %{client_pid: client_pid, session_id: session_id}} = state
    request_id = create_request_id()
    request = %{janus: :keepalive, session_id: session_id, transaction: request_id}

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :keepalive)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info({:create_audio_room, call_id}, state) do
    %{janus: %{client_pid: client_pid, session_id: session_id, handle_id: handle_id}} =
      state

    request_id = create_request_id()

    request =
      %{
        janus: :message,
        session_id: session_id,
        handle_id: handle_id,
        body: %{
          request: :create,
          room: generate_room_id(call_id)
        },
        transaction: request_id
      }

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :create_audio_room)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info(:join_audio_room, state) do
    %{
      janus: %{
        client_pid: client_pid,
        session_id: session_id,
        handle_id: handle_id,
        room_id: room_id
      }
    } =
      state

    request_id = create_request_id()

    request =
      %{
        janus: :message,
        session_id: session_id,
        handle_id: handle_id,
        body: %{
          request: :join,
          room: room_id
        },
        transaction: request_id
      }

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :join_audio_room)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info(:destroy_audio_room, state) do
    %{
      janus: %{
        client_pid: client_pid,
        session_id: session_id,
        handle_id: handle_id,
        room_id: room_id
      }
    } =
      state

    request_id = create_request_id()

    request =
      %{
        janus: :message,
        session_id: session_id,
        handle_id: handle_id,
        body: %{
          request: :destroy,
          room: room_id
        },
        transaction: request_id
      }

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :destroy_audio_room)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info({:ice_candidate, candidate}, state) do
    %{janus: %{client_pid: client_pid, session_id: session_id, handle_id: handle_id}} =
      state

    request_id = create_request_id()

    request =
      %{
        janus: :trickle,
        session_id: session_id,
        handle_id: handle_id,
        candidate: candidate,
        transaction: request_id
      }

    case Client.send_request(client_pid, request) do
      :ok ->
        state = put_in(state[:janus][:requests][request_id], :ice_candidate)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info({:janus, message}, state) do
    request_id = message["transaction"]

    case pop_in(state, [:janus, :requests, request_id]) do
      # Event
      {nil, state} ->
        case handle_event(message) do
          :skip ->
            {:noreply, state}

          event ->
            state = put_in(state[:janus][:events][event], message)
            {:noreply, state, next_action(event)}
        end

      # Async response
      {request, new_state} ->
        case handle_response(request, message) do
          :skip ->
            {:noreply, state}

          :ok ->
            {:noreply, new_state, next_action(request)}

          {:ok, result} ->
            state = update_state(request, result, new_state)

            {:noreply, state, next_action(request)}

          {:error, reason} ->
            {:stop, reason}
        end
    end
  end

  def handle_event(%{
        "janus" => "event",
        "plugindata" => %{"data" => %{"audiobridge" => "joined"}}
      }) do
    :accept
  end

  def handle_event(%{
        "janus" => "event",
        "plugindata" => %{"data" => %{"audiobridge" => "destroyed"}}
      }) do
    :skip
  end

  defp handle_response(:create_session, %{"janus" => "success", "data" => %{"id" => session_id}}) do
    {:ok, session_id}
  end

  defp handle_response(:attach_plugin, %{"janus" => "success", "data" => %{"id" => handle_id}}) do
    {:ok, handle_id}
  end

  defp handle_response(:create_audio_room, %{
         "janus" => "success",
         "plugindata" => %{"data" => %{"audiobridge" => "created", "room" => room_id}}
       }),
       do: {:ok, room_id}

  defp handle_response(:join_audio_room, %{
         "janus" => "event",
         "plugindata" => %{"data" => %{"audiobridge" => "joined"}}
       }) do
    :ok
  end

  defp handle_response(:destroy_audio_room, %{
         "janus" => "success",
         "plugindata" => %{"data" => %{"audiobridge" => "destroyed"}}
       }) do
    {:ok, nil}
  end

  defp handle_response(:keepalive, %{"janus" => "ack"}), do: :ok

  defp handle_response(_request, %{"janus" => "ack"}), do: :skip

  # "error" => => %{"code" => _code, "reason" => _reason}
  defp handle_response(request, %{"janus" => "error", "error" => error}) do
    Logger.error("Request: #{inspect(request)} failed with error: #{inspect(error)}")

    reason =
      case request do
        :create_session -> :create_session_failed
        :attach_plugin -> :attach_plugin_failed
        ## TODP: this error handling doesnt work since janus message is in different format
        # :create_audio_room -> :create_audio_room_failed
        :ice_candidate -> :trickle_failed
      end

    {:error, reason}
  end

  defp update_state(:create_session, session_id, state) do
    put_in(state[:janus][:session_id], session_id)
  end

  defp update_state(:attach_plugin, handle_id, state) do
    put_in(state[:janus][:handle_id], handle_id)
  end

  defp update_state(:create_audio_room, room_id, state) do
    put_in(state[:janus][:room_id], room_id)
  end

  defp update_state(:destroy_audio_room, room_id, state) do
    put_in(state[:janus][:room_id], room_id)
  end

  defp next_action(:create_session), do: {:continue, :attach_plugin}
  defp next_action(:attach_plugin), do: {:continue, :attached}
  defp next_action(:create_audio_room), do: {:continue, :audio_room_created}
  defp next_action(:join_audio_room), do: {:continue, :audio_room_joined}
  defp next_action(:destroy_audio_room), do: {:continue, :audio_room_destroyed}
  defp next_action(:keepalive), do: {:continue, :keepalive}
  defp next_action(_), do: :noop

  defp via_tuple(id), do: {:via, Registry, {ChordLab.Registry, id}}

  defp create_request_id(), do: UUID.uuid1()

  def generate_room_id(string) when is_binary(string) do
    :erlang.phash2(string, @max_room_id)
  end
end
