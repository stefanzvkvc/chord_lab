# ChordLab

Welcome to **ChordLab** — a test tool designed to demonstrate the power and flexibility of the [Chord library](https://hex.pm/packages/chord). Currently, ChordLab supports a **stateless chat simulation**, with plans to expand into video call simulations, game sessions, and collaborative documents.

## 📖 Getting Started

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

## 🧪 Features in Action

### Chat Tool

- **Public Chat**: Join a shared space where all participants can communicate in real time.
- **Private Conversations**: Select an online user and start a one-on-one chat.
- **Delta Syncing**: Leverages Chord's delta-based synchronization for efficient updates.
- **Unread Message Badges**: Easily identify new messages.
- **Online Presence**: Displays a list of active users and tracks their availability.
- **Network Simulation**: Test the application's resilience with a simulated network disconnection and automatic reconnection, preserving state and syncing missed updates efficiently.

## 🔮 Future Plans

In addition to the chat tool, upcoming features include:

- **Video Call Session Simulation**: Test real-time state synchronization for video calls.
- **Game Session Management**: Simulate multiplayer games with shared state.
- **Collaborative Document Editing**: Demonstrate real-time collaboration on documents.

## 🛠️ Powered By

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) for real-time web interfaces.
- [Chord](https://hex.pm/packages/chord) for context management and delta syncing.

## 💡 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve ChordLab.

---

🎉 **Start exploring ChordLab today and see how powerful real-time state synchronization can be!**
