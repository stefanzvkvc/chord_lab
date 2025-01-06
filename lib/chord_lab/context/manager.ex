defmodule ChordLab.Context.Manager do
  @moduledoc """
  Acts as a decision-maker or router for context-related operations, whether stateful or stateless.
  """
  @initial_messages_state %{}

  # Public API

  def sync(conversations, conversation_id, client_version) do
    result = Chord.sync_context(conversation_id, client_version)
    case result do
      {:full_context, %{context: context, version: version}} ->
        update_conversations(conversations, conversation_id, context.messages, version)

      {:delta, %{delta: delta, version: version}} ->
        conversation_messages = get_messages_for_conversation(conversations, conversation_id)

        updated_messages =
          delta
          |> Map.get(:messages, %{})
          |> Enum.reduce(conversation_messages, &apply_delta/2)

        update_conversations(conversations, conversation_id, updated_messages, version)

      {:no_change, _version} ->
        conversations

      {:error, :not_found} ->
        {:ok, %{context: result}} =
          Chord.set_context(conversation_id, %{messages: @initial_messages_state})

        update_conversations(
          conversations,
          conversation_id,
          result.context.messages,
          result.version
        )
    end
  end

  def send_message(conversations, conversation_id, sender, message) do
    new_message = create_message_payload(sender, message)

    {:ok, %{context: updated, delta: delta}} =
      Chord.update_context(conversation_id, %{messages: new_message})

    conversation_data = prepare_conversation_data(updated.context.messages, updated.version)
    conversations = Map.put(conversations, conversation_id, conversation_data)

    {conversations, delta}
  end

  def handle_delta(conversations, active_conversation, delta) do
    %{
      version: version,
      delta: %{
        messages: messages
      },
      context_id: conversation_id
    } = delta

    if active_conversation == conversation_id do
      conversation_messages = get_messages_for_conversation(conversations, conversation_id)

      conversation_data =
        messages
        |> Enum.reduce(conversation_messages, fn {message_id, message_data}, acc ->
          case Map.get(message_data, :action) do
            :added ->
              message = Map.get(message_data, :value)
              Map.put(acc, message_id, message)

            ## TODO:
            ## when action is modified, update message data
            ## when action is removed, remove message from message state
            _ ->
              acc
          end
        end)
        |> prepare_conversation_data(version)

      {:active, Map.put(conversations, conversation_id, conversation_data)}
    else
      {:inactive, conversation_id, messages}
    end
  end

  # Private Helpers

  defp apply_delta({message_id, message_data}, acc) do
    case Map.get(message_data, :action) do
      :added ->
        message = Map.get(message_data, :value)
        Map.put(acc, message_id, message)

      ## TODO:
      ## when action is modified, update message data
      ## when action is removed, remove message from message state
      _ ->
        acc
    end
  end

  defp update_conversations(conversations, conversation_id, messages, version) do
    conversation_data = prepare_conversation_data(messages, version)
    Map.put(conversations, conversation_id, conversation_data)
  end

  defp get_messages_for_conversation(conversations, conversation_id) do
    conversations[conversation_id][:messages] || %{}
  end

  defp prepare_conversation_data(messages, version) do
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
    %{UUID.uuid1() => %{sender: sender, text: message, timestamp: DateTime.utc_now()}}
  end

  # Architecture Helpers

  # defp get_architecture, do: Application.get_env(:chord_lab, :architecture)
end
