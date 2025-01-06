defmodule ChordLabWeb.Components.ModalComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <%= if @show_username_modal do %>
      <!-- Username Modal -->
      <div class="fixed inset-0 flex items-center justify-center bg-gray-900/75">
        <div class="bg-gray-800 rounded-lg p-6 text-center w-96">
          <h2 class="text-2xl font-bold mb-4 text-white">Enter Your Username</h2>
          <form phx-submit="set_username">
            <input
              type="text"
              name="username"
              placeholder="Username"
              class="w-full p-3 rounded-md bg-gray-700 text-white placeholder-gray-400 focus:outline-none focus:ring focus:ring-purple-500"
              required
            />
            <button
              type="submit"
              class="mt-4 w-full p-3 bg-purple-600 hover:bg-purple-500 rounded-md text-white font-semibold"
            >
              Join Chat
            </button>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end
