let ConnectionSimulator = {
  mounted() {
    this.handleEvent("simulate_connection_loss", ({timer: timer}) => {
      // Simulate connection restoration after the specified timer
      setTimeout(() => {
        this.pushEvent("simulate_connection_restore", {});
      }, timer);
    });
  }
}

export { ConnectionSimulator };