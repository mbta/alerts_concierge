// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
require("babel-polyfill");
import touchSupport from "./touch-support";
import radioToggle from "./radio-toggle";
import selectRoute from "./select-route";
import selectRouteChoices from "./select-route-choices";
import selectStop from "./select-stop";
import helpText from "./help-text";
import daySelector from "./day-selector";
import schedule from "./schedule";
import phoneMask from "./phone-mask";
import customTimeSelect from "./custom-time-select";
import deleteModal from "./delete-modal";
import tripCard from "./trip-card";
import flashFocus from "./flash-focus";
import pubsubFactory from "PubSub";
const pubsub = new pubsubFactory();

touchSupport();
selectRoute();
selectRouteChoices();
radioToggle(pubsub);
selectStop();
helpText();
daySelector();
schedule(pubsub);
phoneMask();
customTimeSelect(pubsub);
deleteModal();
tripCard();
flashFocus();
