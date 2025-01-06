defmodule ChordLabWeb.Components.Chat.MessageInputComponent do
  use Phoenix.LiveComponent
  alias ChordLabWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="py-6">
      <form phx-submit="send_message">
        <div class="flex items-center bg-gray-700/40 rounded-lg overflow-hidden">
          <input
            type="text"
            name="message"
            class="flex-1 p-3 text-gray-200 placeholder-gray-400 bg-transparent focus:outline-none focus:ring focus:ring-purple-600"
            placeholder="Type a message"
          />
          <button
            type="submit"
            class="p-3 bg-purple-600 hover:bg-purple-500 flex items-center justify-center transition"
          >
            <CoreComponents.icon name="hero-paper-airplane" class="w-6 h-6"/>
          </button>
        </div>
      </form>
    </div>
    """
  end
end
