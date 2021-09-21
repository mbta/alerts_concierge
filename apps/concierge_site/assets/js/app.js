// Import CSS
import "../css/app.scss";

// Import dependencies
import "phoenix_html";
import "bootstrap";

// Import local files
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
import feedbackForm from "./feedback-form";

const pubsub = new pubsubFactory();

// Run all JS
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
feedbackForm();
