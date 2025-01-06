defmodule ChordLabWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chord_lab,
    pubsub_server: ChordLab.PubSub
end
