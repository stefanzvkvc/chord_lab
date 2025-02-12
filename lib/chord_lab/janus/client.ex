defmodule ChordLab.Janus.Client do
  use WebSockex
  require Logger

  @scheme "ws"
  @host "localhost"
  @port 8188
  @headers [{"Sec-WebSocket-Protocol", ["janus-protocol"]}]

  def start_link(opts \\ []) do
    uri = %URI{
      host: @host,
      port: @port,
      scheme: @scheme
    }

    conn = WebSockex.Conn.new(uri, extra_headers: @headers)

    state = %{parent_pid: opts[:pid]}

    WebSockex.start_link(conn, __MODULE__, state)
  end

  def send_request(client, request) do
    Logger.debug("REQ: #{inspect request}")
    message = Jason.encode!(request)

    case WebSockex.send_frame(client, {:text, message}) do
      :ok ->
        :ok

      {:error, reason} = error ->
        Logger.error(
          "Error on sending frame: #{inspect(message)} through the websocket: #{inspect(client)}. Reason: #{reason}"
        )

        error
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    {:ok, state}
  end

  def handle_frame({:text, message}, state) do
    %{parent_pid: parent_pid} = state
    message = Jason.decode!(message)
    Logger.debug("RESP: #{inspect message}")
    send(parent_pid, {:janus, message})
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end
end
