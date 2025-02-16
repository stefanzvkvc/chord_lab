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
          setupChannelEventListeners();
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
          channel.push("join_audio_room", payload)
            .receive("ok", (resp) => {
              console.log("Joined audio room successfully", resp);

              // Step 3: Initialize WebRTC, then create and send SDP Offer
              setupWebRTC()
                .then(() => createOffer(channel))
                .then(() => {
                  console.log("WebRTC initialized & SDP Offer sent. Now pushing 'ringing' event.");
                  this.pushEvent("ringing", resp);
                })
                .catch((error) => {
                  console.error("Error during WebRTC initialization:", error);
                });
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


    // Handle "accept" event to accept audio call
    this.handleEvent("accept", (payload) => {
      console.log("Received accept event from LiveView:", payload);

      channel.push("join_audio_room", payload)
        .receive("ok", (resp) => {
          console.log("Joined audio room successfully", resp);

          // Initialize WebRTC, then create and send SDP Offer
          setupWebRTC()
            .then(() => createOffer(channel))
            .then(() => {
              console.log("WebRTC initialized & SDP Offer sent. Now pushing 'accepted' event.");
              this.pushEvent("accepted", resp);
            })
            .catch((error) => {
              console.error("Error during WebRTC initialization:", error);
            });
        })
        .receive("error", (resp) => {
          console.error("Failed to cancel audio call", resp);
        });
    });

    function setupChannelEventListeners() {
      if (!channel) {
        console.error("Channel is not available to set event listeners.");
        return;
      }

      channel.on("sdp_answer", (payload) => {
        console.log("Received SDP answer from server:", payload.jsep);

        if (!peerConnection) {
          console.error("PeerConnection is not initialized before receiving SDP Answer.");
          return;
        }

        peerConnection.setRemoteDescription(new RTCSessionDescription(payload.jsep))
          .then(() => console.log("SDP Answer applied successfully"))
          .catch((error) => console.error("Error applying SDP Answer:", error));
      });
    }

    function setupWebRTC() {
      return new Promise((resolve, reject) => {
        const configuration = {
          iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
        };
        peerConnection = new RTCPeerConnection(configuration);

        // Handle ICE Candidate Generation
        peerConnection.onicecandidate = (event) => {
          if (event.candidate) {
            console.log("Generated ICE candidate:", event.candidate);
            channel.push("ice_candidate", { candidate: event.candidate })
              .receive("ok", (resp) => console.log("Sent ICE Candidate successfully", resp))
              .receive("error", (err) => console.error("Failed to send ICE Candidate", err));
          }
        };

        // Handle Remote Stream Tracks
        peerConnection.ontrack = (event) => {
          console.log("Remote track received:", event.track);
          let remoteAudio = document.getElementById("remote-audio");
          if (remoteAudio) {
            remoteAudio.srcObject = event.streams[0];
          }
        };

        // Get local audio stream
        navigator.mediaDevices.getUserMedia({ audio: true })
          .then((stream) => {
            console.log("Local media stream obtained:", stream);
            localStream = stream;
            stream.getTracks().forEach(track => peerConnection.addTrack(track, stream));
            resolve();
          })
          .catch((error) => {
            console.error("Error accessing media devices:", error);
            reject(error);
          });
      });
    }

    function createOffer(channel) {
      return new Promise((resolve, reject) => {
        peerConnection.createOffer()
          .then((offer) => {
            return peerConnection.setLocalDescription(offer)
              .then(() => offer);
          })
          .then((offer) => {
            console.log("SDP Offer created and set as local description:", offer);

            channel.push("sdp_offer", { jsep: offer })
              .receive("ok", (resp) => {
                console.log("SDP Offer sent successfully:", resp);
                resolve();
              })
              .receive("error", (err) => {
                console.error("Failed to send SDP Offer:", err);
                reject(err);
              });
          })
          .catch((error) => {
            console.error("Error creating SDP Offer:", error);
            reject(error);
          });
      });
    }
  }
};

export { AudioCallChannel };
