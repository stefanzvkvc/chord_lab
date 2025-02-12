defmodule ChordLab.Chat.Manager do
  @moduledoc """
  Wrapper around Chord for managing context synchronization and delta updates.
  """
  @initial_messages_state %{}

  # Public API

  def sync(chats, chat_id, client_version) do
    case Chord.sync_context(chat_id, client_version) do
      {:full_context, %{context: context, version: version}} ->
        update_chats(chats, chat_id, context.messages, version)

      {:delta, %{delta: delta, version: version}} ->
        chat_messages = get_chat_messages(chats, chat_id)

        updated_messages =
          delta
          |> Map.get(:messages, %{})
          |> Enum.reduce(chat_messages, &apply_delta/2)

        update_chats(chats, chat_id, updated_messages, version)

      {:no_change, _version} ->
        chats

      {:error, :not_found} ->
        {:ok, %{context: result}} =
          Chord.set_context(chat_id, %{messages: @initial_messages_state})

        update_chats(
          chats,
          chat_id,
          result.context.messages,
          result.version
        )
    end
  end

  def send_message(chats, chat_id, sender, message) do
    new_message = create_message_payload(sender, message)

    {:ok, %{context: updated, delta: delta}} =
      Chord.update_context(chat_id, %{messages: new_message})

    chat_data = prepare_chat_data(updated.context.messages, updated.version)
    chats = Map.put(chats, chat_id, chat_data)

    {chats, delta}
  end

  def handle_delta(chats, chat_id, delta) do
    %{
      version: version,
      delta: %{
        messages: messages
      },
      context_id: context_id
    } = delta

    if chat_id == context_id do
      chat_messages = get_chat_messages(chats, chat_id)

      chat_data =
        messages
        |> Enum.reduce(chat_messages, &apply_delta/2)
        |> prepare_chat_data(version)

      {:active, Map.put(chats, chat_id, chat_data)}
    else
      {:inactive, context_id, messages}
    end
  end

  # Private Helpers

  defp apply_delta({message_id, message_data}, acc) do
    # TODO: Allow editing and deleting messages
    text = message_data[:text][:value]
    timestamp = message_data[:timestamp][:value]
    sender = message_data[:sender][:value]

    message = %{
      text: text,
      timestamp: timestamp,
      sender: sender
    }

    Map.put(acc, message_id, message)
  end

  defp update_chats(chats, chat_id, messages, version) do
    chat_data = prepare_chat_data(messages, version)
    Map.put(chats, chat_id, chat_data)
  end

  defp get_chat_messages(chats, chat_id) do
    chats[chat_id][:messages] || %{}
  end

  defp prepare_chat_data(messages, version) do
    sorted_messages =
      messages
      |> Enum.sort_by(fn {_id, message} -> message.timestamp end)
      |> Enum.into(%{})

    %{
      messages: sorted_messages,
      version: version
    }
  end

  defp create_message_payload(sender, message) do
    %{
      UUID.uuid1() => %{
        sender: sender,
        text: message,
        timestamp: DateTime.utc_now() |> DateTime.to_string()
      }
    }
  end
end
