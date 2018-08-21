import "promise/polyfill"

import * as React from "react";
import * as ReactDOM from "react-dom";

import { UserSearchPage } from "./user_search_page";

ReactDOM.render(
  <UserSearchPage />,
  document.getElementById("admin-app")
);
