import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import selectStation from '../js/select-station';

describe("selectStation", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  beforeEach(function() {
    $("body").append(tripInfoPageHtml);
    selectStation($);
  });

  afterEach(function() {
    $("body > div").remove()
  });

  describe("immediate changes upon page load", () => {
    it("adds text inputs to the page for station entry", () => {
      const $suggstionContainers = $(".suggestion-container");
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      assert.lengthOf($suggstionContainers, 2);
      assert.lengthOf($originInput, 1);
      assert.lengthOf($destinationInput, 1);
    });
  });

  describe("type ahead suggestions", () => {
    it("adds matching stations to the page when the user types a name into the origin field", () => {
      const $originInput = $("input.subscription-select-origin")
      $originInput.val("Braintree");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      const $suggestions = $(".origin-station-suggestion")
      const braintreeSuggestion = $(".station-name", $suggestions).first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(braintreeSuggestion, "Braintree")
    });

    it("adds matching stations to the page when the user types a name into the destination field", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("Braintree");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      simulateKeyUp($destinationInput[0])

      const $suggestions = $(".destination-station-suggestion")
      const braintreeSuggestion = $(".station-name", $suggestions).first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(braintreeSuggestion, "Braintree")
    })

    it("shows partially matching stations", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("Brain");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      const $suggestions = $(".origin-station-suggestion")
      const braintreeSuggestion = $(".station-name", $suggestions).first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(braintreeSuggestion, "Braintree");
    });

    it("matches case insensitively", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("braintree");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      const $suggestions = $(".origin-station-suggestion")
      const braintreeSuggestion = $(".station-name", $suggestions).first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(braintreeSuggestion, "Braintree");
    });

    it("displays all lines", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("Park Street");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      const $suggestions = $(".origin-station-suggestion")
      const parkStreetSuggestion = $(".line-name", $suggestions).text();

      assert.include(parkStreetSuggestion, "Green Line");
      assert.include(parkStreetSuggestion, "Red Line");
    });
  });

  describe("clicking on a suggestion", () => {
    it("populates the origin input field with the station full name", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("Park");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      $(".origin-station-suggestion").first().mousedown();

      assert.equal($originInput.val(), "Park Street");
    });

    it("populates the destination input field with the station full name", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("Brain");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      simulateKeyUp($destinationInput[0])
      $(".destination-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "Braintree");
    });
  })

  describe("station input losing focus", () => {
    it("populates the origin input field with the first suggestion", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("Park");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      $originInput.focus();
      simulateKeyUp($originInput[0])
      $("input.subscription-select-destination").focus()

      assert.equal($originInput.val(), "Park Street");
    });

    it("populates the destination field with the first suggestion", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("brain");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      $destinationInput.focus();
      simulateKeyUp($destinationInput[0])
      $("input.subscription-select-origin").focus()

      assert.equal($destinationInput.val(), "Braintree");
    });

    it("does nothing when there are no suggestions in the origin field", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("abc123");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      $originInput.focus();
      simulateKeyUp($originInput[0])
      $("input.subscription-select-destination").focus()

      assert.equal($originInput.val(), "abc123");
    });

    it("does nothing when there are no suggestions in the destination", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("abc123");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      $destinationInput.focus();
      simulateKeyUp($destinationInput[0])
      $("input.subscription-select-origin").focus()

      assert.equal($destinationInput.val(), "abc123");
    });
  });

  const tripInfoPageHtml = `
    <div class="enter-trip-info">
      <form>
        <div class="form-group select-station">
          <label for="origin" class="station-input-label form-label">Origin</label>
          <select class="subscription-select-origin no-js" id="subscription_origin" name="subscription[origin]">
            <optgroup label="Red">
              <option value="place-brntn">Braintree</option>
              <option value="place-pktrm">Park Street</option>
            </optgroup>
            <optgroup label="Green-C">
              <option value="place-pktrm">Park Street</option>
            </optgroup>
          </select>
        </div>
        <div class="form-group select-station">
          <label for="destination" class="station-input-label form-label">Destination</label>
          <select class="subscription-select-destination no-js" id="subscription_destination" name="subscription[destination]">
            <optgroup label="Red">
              <option value="place-brntn">Braintree</option>
              <option value="place-pktrm">Park Street</option>
            </optgroup>
            <optgroup label="Green-C">
              <option value="place-pktrm">Park Street</option>
            </optgroup>
          </select>
        </div>
      </form>
    </div>
    `

  function simulateKeyUp(target) {
    const event = document.createEvent("HTMLEvents");
    event.initEvent("keyup", true, true);
    target.dispatchEvent(event);
  }
});
