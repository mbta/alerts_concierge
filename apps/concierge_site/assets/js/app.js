// Import dependencies
import "phoenix_html";
import "bootstrap";

// Import local files
// import socket from "./socket"
import touchSupport from "./touch-support";
import radioToggle from "./radio-toggle";
import selectRouteChoices from "./select-route-choices";
import selectStopChoices from "./select-stop-choices";
import daySelector from "./day-selector";
import schedule from "./schedule";
import phoneMask from "./phone-mask";
import customTimeSelect from "./custom-time-select";
import deleteModal from "./delete-modal";
import flashFocus from "./flash-focus";
import pubsubFactory from "PubSub";
import tripForm from "./trip-form";
import commuteEditForm from "./commute-edit-form";
import selectMultiFix from "./select-multi-fix";
import menuToggle from "./menu";

// Import css
import "../css/app.scss";

const pubsub = new pubsubFactory();

// Run all JS
touchSupport();
selectRouteChoices();
radioToggle(pubsub);
selectStopChoices();
daySelector(pubsub);
schedule(pubsub);
phoneMask();
customTimeSelect(pubsub);
deleteModal();
tripForm();
commuteEditForm();
selectMultiFix();
flashFocus();
menuToggle();
