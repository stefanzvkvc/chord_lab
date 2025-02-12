defmodule ChordLabWeb.Components.AudioCallComponent do
  use Phoenix.Component
  alias ChordLabWeb.Components.AudioCall.{HeaderComponent, CallComponent}

  attr(:current_user, :string, required: true)
  attr(:call_id, :string, required: true)
  attr(:caller, :string, required: true)
  attr(:callee, :string, required: true)
  attr(:status, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col p-6 h-screen">
      <!-- Header -->
      <HeaderComponent.render />
      <!-- Grid -->
      <CallComponent.render current_user={@current_user} call_id={@call_id} caller={@caller} callee={@callee} status={@status}/>
    </div>
    """
  end
end
