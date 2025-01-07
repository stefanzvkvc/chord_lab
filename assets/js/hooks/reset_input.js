let ResetInput = {
    mounted() {
      this.handleEvent("clear_input", () => {
        this.el.reset(); // Reset the entire form
      });
    },
  };
  
  export { ResetInput };