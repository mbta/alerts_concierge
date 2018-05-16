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
import formHelpers from './form-helpers';
import selectRoute from "./select-route";
import selectStop from "./select-stop";
import toggleInput from "./toggle-input";
import helpText from "./help-text";
import daySelector from "./day-selector";
import schedule from "./schedule";
import toggleTripType from "./toggle-trip-type";
import phoneMask from "./phone-mask";
import customTimeSelect from "./custom-time-select";
import pubsubFactory from "PubSub";
const pubsub = new pubsubFactory();

const path = window.location.pathname;

touchSupport();
formHelpers();
selectRoute();
selectStop();
toggleInput();
helpText();
daySelector();
schedule(pubsub);
phoneMask();
customTimeSelect(pubsub);
if (path.match(/\/trip_type$/)) {
  toggleTripType();
}
