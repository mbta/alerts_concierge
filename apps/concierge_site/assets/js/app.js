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

import selectStation from './select-station';
import selectBusRoute from './select-bus-route';
import selectAmenityStation from './select-amenity-station';
import selectTrip from './select-trip';
import myAccountToggleSections from './my-account-toggle-sections';
import formHelpers from './form-helpers';
import vacationDatepicker from './vacation-datepicker';

selectBusRoute();
selectStation();
selectAmenityStation();
selectTrip();
myAccountToggleSections();
formHelpers();
vacationDatepicker();

document.body.className = document.body.className.replace("no-js", "js");
