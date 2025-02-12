import { ConnectionSimulator } from "./hooks/connection_simulator.js";
import { ScrollToLastMessage } from "./hooks/scroll_to_last_message.js";
import { ResetInput } from "./hooks/reset_input.js";
import { AudioCallChannel } from "./hooks/audio_call_channel.js";
let Hooks = {
    ConnectionSimulator,
    ScrollToLastMessage,
    ResetInput,
    AudioCallChannel
};
export { Hooks };