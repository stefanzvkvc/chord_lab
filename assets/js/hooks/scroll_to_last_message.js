let ScrollToLastMessage = {
    mounted() {
      this.scrollToLastMessage()
    },
    updated() {
      this.scrollToLastMessage()
    },
    scrollToLastMessage() {
      let messagesContainer = this.el
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
  
  export { ScrollToLastMessage };