# ChordLab

Welcome to **ChordLab** - a test tool designed to demonstrate the power and flexibility of the [Chord library](https://hex.pm/packages/chord). Currently, ChordLab supports a **stateless chat simulation**, with plans to expand into audio call simulations, game sessions, and collaborative documents.

## Getting started

### Prerequisites

Ensure you have the following installed:

- Elixir ~> 1.14
- Phoenix ~> 1.7

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/stefanzvkvc/chord_lab
   cd chord_lab
   ```

2. Install dependencies:

   ```bash
   mix deps.get
   npm install --prefix assets
   ```

3. Start the server:

   ```bash
   mix phx.server
   ```

4. Open your browser and navigate to:

   ```
   http://localhost:4000
   ```

## Features in action

### Chat tool

- **Public chat**: Join a shared space where all participants can communicate in real time.
- **Private conversations**: Select an online user and start a one-on-one chat.
- **Delta syncing**: Leverages Chord's delta-based synchronization for efficient updates.
- **Unread message badges**: Easily identify new messages.
- **Online presence**: Displays a list of active users and tracks their availability.
- **Network simulation**: Test the application's resilience with a simulated network disconnection and automatic reconnection, preserving state and syncing missed updates efficiently.

## Future plans

In addition to the chat tool, upcoming features include:

- **Audio call session simulation**: Test real-time audio calls.
- **Game session management**: Simulate multiplayer games with shared state.
- **Collaborative document editing**: Demonstrate real-time collaboration on documents.

## Powered by

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) for real-time web interfaces.
- [Chord](https://hex.pm/packages/chord) for context management and delta syncing.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve ChordLab.

---

**Start exploring ChordLab today and see how powerful real-time state synchronization can be!**
