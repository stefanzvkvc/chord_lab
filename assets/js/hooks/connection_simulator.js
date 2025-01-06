let ConnectionSimulator = {
  mounted() {
    this.handleEvent("simulate_connection_loss", () => {
      console.log("Simulating connection loss...");

      // Disconnect the LiveSocket
      this.liveSocket.disconnect();

      // Reconnect after 15 seconds (simulate recovery)
      setTimeout(() => {
        console.log("Reconnecting...");
        this.liveSocket.connect();
      }, 15000); // Adjust the delay as needed
    });
  }
}

export { ConnectionSimulator };