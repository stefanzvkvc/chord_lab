let AudioCallChannel = {
  mounted() {
    let channel;

    // Handle "join" event to join the audio channel
    this.handleEvent("join", (payload) => {
      console.log("Received join event from LiveView:", payload);

      // Create and join the audio channel
      channel = this.liveSocket.socket.channel(payload.topic, { username: payload.username });
      channel.join()
        .receive("ok", (resp) => {
          console.log("Joined channel successfully", resp);
        })
        .receive("error", (resp) => {
          console.error("Unable to join channel", resp);
        });
    });

    // Handle "call" event
    this.handleEvent("call", (payload) => {
      console.log("Received call event from LiveView:", payload);

      // Step 1: Request the server to create an audio room
      channel.push("create_audio_room", payload)
        .receive("ok", (resp) => {
          console.log("Audio room created successfully", resp);

          // Step 2: Join the audio room
          channel.push("join_audio_room", {})
            .receive("ok", (resp) => {
              console.log("Joined audio room successfully", resp);
              this.pushEvent("ringing", resp);
            })
            .receive("error", (resp) => {
              console.error("Failed to join audio room", resp);
            });
        })
        .receive("error", (resp) => {
          console.error("Failed to create audio room", resp);
        });
    });

    // Handle "reject" event to reject audio call
    this.handleEvent("reject", (payload) => {
      console.log("Received rejected event from LiveView:", payload);

      channel.push("reject", payload)
        .receive("ok", (resp) => {
          console.log("Audio call rejected successfully", resp);
          this.pushEvent("rejected", resp);
        })
        .receive("error", (resp) => {
          console.error("Failed to reject audio call", resp);
        });
    });

    // Handle "cancel" event to end audio call
    this.handleEvent("cancel", (payload) => {
      console.log("Received cancel event from LiveView:", payload);

      channel.push("cancel", payload)
        .receive("ok", (resp) => {
          console.log("Audio call canceled successfully", resp);
          this.pushEvent("canceled", resp);
        })
        .receive("error", (resp) => {
          console.error("Failed to cancel audio call", resp);
        });
    });
  }
};

export { AudioCallChannel };
