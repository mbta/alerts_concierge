import filterSuggestions from './filter-suggestions';

export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {
    route: undefined,
  };

  if ($(".enter-trip-info").length) {
    props.allRoutes = generateRouteList();
    attachSuggestionInput();
  }

  function attachSuggestionInput() {
    $("label[for='route']").after(renderRouteInput());
  }

  function renderRouteInput() {
    return `
      <input type="text" name="route" placeholder="Enter your bus number" class="subscription-select subscription-select-route station-input" data-valid="false" autocomplete="off"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
  }

  function renderRouteSuggestion(route) {
    return `
      <div class="station-suggestion bus-route">
        <span class="route-name">${route}</span>
        <span class="route-logo" style="padding-right: 10px;">${renderBusIcon()}</span>
      </div>
    `
  }

  function renderBusIcon() {
    return `
      <svg aria-hidden="false" class="icon icon-with-circle icon-bus " version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 42 42" data-toggle="tooltip" title="" preserveAspectRatio="xMidYMid meet" data-original-title="Bus">
        <circle r="20" cx="20" cy="20" class="icon-circle icon-bus-circle" fill="#ffce0c" transform="translate(1,1)"></circle>
        <g fill-rule="evenodd" class="icon-image icon-bus-image" style="fill: #000;" transform="translate(4,5) scale(1.4)">
          <path d="M15.0000409,19 L8.99995829,19 C8.99503143,19.5531447 8.55421988,20 8.00104344,20 L6.99895656,20 C6.45028851,20 6.00493267,19.5615199 6.00004069,18.9999777 C5.44710715,18.996349 5,18.5507824 5,17.9975592 L5,17.5024408 C5,16.948808 5,16.0551184 5,15.4982026 L5,5.00179743 C5,4.44851999 5.44994876,4 6.00684547,4 L17.9931545,4 C18.5492199,4 19,4.44488162 19,5.00179743 L19,15.4982026 C19,16.05148 19,16.9469499 19,17.5024408 L19,17.9975592 C19,18.5489355 18.5537115,18.9963398 17.9999585,18.9999777 C17.9950433,19.5531326 17.5542273,20 17.0010434,20 L15.9989566,20 C15.4502958,20 15.0049445,19.5615315 15.0000409,19 Z M13,8 L18,8 L18,14 L13,14 L13,8 Z M6,8 L11,8 L11,14 L6,14 L6,8 Z M8,5 L16,5 L16,7 L8,7 L8,5 Z M16,16 C16,15.4477153 16.4438648,15 17,15 C17.5522847,15 18,15.4438648 18,16 C18,16.5522847 17.5561352,17 17,17 C16.4477153,17 16,16.5561352 16,16 Z M13,16 C13,15.4477153 13.4438648,15 14,15 C14.5522847,15 15,15.4438648 15,16 C15,16.5522847 14.5561352,17 14,17 C13.4477153,17 13,16.5561352 13,16 Z M9,16 C9,15.4477153 9.44386482,15 10,15 C10.5522847,15 11,15.4438648 11,16 C11,16.5522847 10.5561352,17 10,17 C9.44771525,17 9,16.5561352 9,16 Z M6,16 C6,15.4477153 6.44386482,15 7,15 C7.55228475,15 8,15.4438648 8,16 C8,16.5522847 7.55613518,17 7,17 C6.44771525,17 6,16.5561352 6,16 Z">
        </path></g>
      </svg>
    `
  }

  function generateRouteList() {
    let routes = [];
    const $options = $("select.subscription-select-route").children();
    $options.each(function(i, option) {
      if (i !== 0) {
        let routeName = option.value
        routes.push(routeName);
      }
    });
    return routes;
  }

  function typeahead(event) {
    const query = event.target.value;
    if (query.length > 0) {
      const matchingRoutes = filterSuggestions(query, props.allRoutes);
      const suggestionElements = matchingRoutes.map(function(route) {
        return renderRouteSuggestion(route);
      });

      const $suggestionContainer = $('.suggestion-container');
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountRouteSuggestions();
    }
  }

  function unmountRouteSuggestions() {
    $(`.bus-route`).remove();
  }

  function validateRouteInput(routeName) {
    const $routeInput = $('.subscription-select-route');
    $routeInput.attr("data-valid", props.allRoutes.includes(routeName));
  }

  function pickFirstSuggestion(event) {
    const $routeInput = $('.subscription-select-route');
    const $firstSuggestion = $(`.bus-route > .route-name`).first();

    if ($firstSuggestion.length) {
      const routeName = $firstSuggestion.text();
      $routeInput.val(routeName);
      validateRouteInput(routeName)
    }

    unmountRouteSuggestions();
  }

  function assignSuggestion(event) {
    const routeName = event.target.children[0].textContent;
    const $routeInput = $('.subscription-select-route');

    $routeInput.val(routeName);
    validateRouteInput(routeName)
    unmountRouteSuggestions();
  }

  $(document).on(
    "keyup", ".subscription-select-route", {}, typeahead);
  $(document).on(
    "keyup", ".subscription-select-route", {}, validateRouteInput);
  $(document).on(
    "focusout", ".subscription-select-route", {}, pickFirstSuggestion);
  $(document).on(
    "mousedown", ".bus-route", {}, assignSuggestion);
}
