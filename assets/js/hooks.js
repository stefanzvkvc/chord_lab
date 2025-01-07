import { ConnectionSimulator } from "./hooks/connection_simulator.js";
import { ScrollToLastMessage } from "./hooks/scroll_to_last_message.js";
import { ResetInput } from "./hooks/reset_input.js";
let Hooks = {
    ConnectionSimulator,
    ScrollToLastMessage,
    ResetInput
};
export { Hooks };