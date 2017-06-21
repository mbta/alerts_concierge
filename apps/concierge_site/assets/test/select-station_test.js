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

    describe ("when one station has already been selected", () => {
      it("only shows stations on the selected station's lines", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("Braintree");
        simulateKeyUp($originInput[0])
        $(".origin-station-suggestion").first().mousedown();

        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("Ken");
        const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");
        simulateKeyUp($destinationInput[0]);

        const $suggestions = $(".destination-station-suggestion");
        const suggestionText = $(".station-name", $suggestions).text();

        assert.lengthOf($suggestions, 1);
        assert.equal(suggestionText, "Kendall/MIT");
      });

      it("does not show the same station as a suggestion even if the text matches", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("Braintree");
        simulateKeyUp($originInput[0])
        $(".origin-station-suggestion").first().mousedown();

        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("Braintree");
        const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");
        simulateKeyUp($destinationInput[0]);

        const $suggestions = $(".destination-station-suggestion");

        assert.lengthOf($suggestions, 0);
      });
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

    it("updates the data-station-id attribute of the origin input", () => {
      const $originInput = $("input.subscription-select-origin");

      $originInput.val("Park");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($originInput.attr("data-station-id"), "place-pktrm");
    });

    it("populates the destination input field with the station full name", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("Brain");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      simulateKeyUp($destinationInput[0])
      $(".destination-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "Braintree");
    });

    it("updates the data-station-id attribute of the destination input", () => {
      const $destinationInput = $("input.subscription-select-destination");

      $destinationInput.val("Brain");
      simulateKeyUp($destinationInput[0]);
      $(".destination-station-suggestion").first().mousedown();

      assert.equal($destinationInput.attr("data-station-id"), "place-brntn");
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

    it("updates the data-station-id attribute of the origin input", () => {
      const $originInput = $("input.subscription-select-origin");

      $originInput.val("Park");
      $originInput.focus();
      simulateKeyUp($originInput[0]);
      $("input.subscription-select-destination").focus();

      assert.equal($originInput.attr("data-station-id"), "place-pktrm");
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

    it("updates the data-station-id attribute of the destination input", () => {
      const $destinationInput = $("input.subscription-select-destination");

      $destinationInput.val("brain");
      $destinationInput.focus();
      simulateKeyUp($destinationInput[0]);
      $("input.subscription-select-origin").focus();

      assert.equal($destinationInput.attr("data-station-id"), "place-brntn");
    });

    it("does nothing when there are no suggestions in the origin field", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("abc123");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      $originInput.focus();
      simulateKeyUp($originInput[0])
      $("input.subscription-select-destination").focus()

      assert.equal($originInput.val(), "abc123");
      assert.equal($originInput.attr("data-station-id"), null);
    });

    it("does nothing when there are no suggestions in the destination", () => {
      const $destinationInput = $("input.subscription-select-destination");
      $destinationInput.val("abc123");
      const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

      $destinationInput.focus();
      simulateKeyUp($destinationInput[0])
      $("input.subscription-select-origin").focus()

      assert.equal($destinationInput.val(), "abc123");
      assert.equal($destinationInput.attr("data-station-id"), null);
    });
  });

  describe("station input field validation", () => {
    describe("typing in the station input fields", () => {
      it("changes the data-valid attribute of the origin input to true when the value exactly matches a station name", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("Park Street");
        simulateKeyUp($originInput[0])

        assert.equal("true", $originInput.attr("data-valid"));
      });

      it("changes the data-valid attribute of the origin input to false when the value does not match a station name", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("abc123");
        simulateKeyUp($originInput[0])

        assert.equal("false", $originInput.attr("data-valid"));
      });

      it("updates the data-station-id attribute of the origin input when the value exactly matches a station name", () => {
        const $originInput = $("input.subscription-select-origin");

        $originInput.val("Park Street");
        simulateKeyUp($originInput[0]);

        assert.equal("place-pktrm", $originInput.attr("data-station-id"));
      });

      it("nullifies the data-station-id attribute of the origin input when the value does not match a station name", () => {
        const $originInput = $("input.subscription-select-origin");

        $originInput.val("Park Street");
        simulateKeyUp($originInput[0]);
        $originInput.val("abc123");
        simulateKeyUp($originInput[0]);

        assert.equal(null, $originInput.attr("data-station-id"));
      });

      it("changes the data-valid attribute of the destination input to true when the value exactly matches a station name", () => {
        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("Braintree");
        simulateKeyUp($destinationInput[0])

        assert.equal("true", $destinationInput.attr("data-valid"));
      });

      it("changes the data-valid attribute of the destination input to false when the value does not match a station name", () => {
        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("123abc");
        simulateKeyUp($destinationInput[0])

        assert.equal("false", $destinationInput.attr("data-valid"));
      });

      it("updates the data-station-id attribute of the destination input when the value exactly matches a station name", () => {
        const $destinationInput = $("input.subscription-select-destination");

        $destinationInput.val("Braintree");
        simulateKeyUp($destinationInput[0]);

        assert.equal("place-brntn", $destinationInput.attr("data-station-id"));
      });

      it("nullifies the data-station-id attribute of the destination input when the value does not match a station name", () => {
        const $destinationInput = $("input.subscription-select-destination");

        $destinationInput.val("Braintree");
        simulateKeyUp($destinationInput[0]);
        $destinationInput.val("abc123");
        simulateKeyUp($destinationInput[0]);

        assert.equal(null, $destinationInput.attr("data-station-id"));
      });
    });

    describe("clicking on a suggestion", () => {
      it("changes the data-valid attribute of the origin input to true", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("Park");
        const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

        simulateKeyUp($originInput[0])

        $(".origin-station-suggestion").first().mousedown();

        assert.equal("true", $originInput.attr("data-valid"));
      });

      it("changes the data-valid attribute of the destination input to true", () => {
        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("Brain");
        const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

        simulateKeyUp($destinationInput[0])

        $(".destination-station-suggestion").first().mousedown();

        assert.equal("true", $destinationInput.attr("data-valid"));
      });
    });

    describe("station input losing focus", () => {
      it("changes the data-valid attribute of the origin input to true when there is at least one suggestion", () => {
        const $originInput = $("input.subscription-select-origin");
        $originInput.val("Park");
        const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

        $originInput.focus();
        simulateKeyUp($originInput[0])
        $("input.subscription-select-destination").focus();

        assert.equal("true", $originInput.attr("data-valid"));
      });

      it("changes the data-valid attribute of the destination input to true when there is at least one suggestion", () => {
        const $destinationInput = $("input.subscription-select-destination");
        $destinationInput.val("brain");
        const $suggestionContainer = $("input.subscription-select-destination + .suggestion-container");

        $destinationInput.focus();
        simulateKeyUp($destinationInput[0])
        $("input.subscription-select-origin").focus();

        assert.equal("true", $destinationInput.attr("data-valid"));
      });
    });
  });

  const tripInfoPageHtml = `
    <div class="enter-trip-info">
      <form class="trip-info-form subway">
        <div class="form-group select-station">
          <label for="origin" class="station-input-label form-label">Origin</label>
          <select class="subscription-select-origin no-js" id="subscription_origin" name="subscription[origin]">
            <optgroup label="Red Line">
              <option value="place-brntn">Braintree</option>
              <option value="place-pktrm">Park Street</option>
              <option value="place-knncl">Kendall/MIT</option>
            </optgroup>
            <optgroup label="Green Line C">
              <option value="place-kencl">Kenmore</option>
              <option value="place-pktrm">Park Street</option>
            </optgroup>
          </select>
        </div>
        <div class="form-group select-station">
          <label for="destination" class="station-input-label form-label">Destination</label>
          <select class="subscription-select-destination no-js" id="subscription_destination" name="subscription[destination]">
            <optgroup label="Red Line">
              <option value="place-brntn">Braintree</option>
              <option value="place-pktrm">Park Street</option>
              <option value="place-knncl">Kendall/MIT</option>
            </optgroup>
            <optgroup label="Green Line C">
              <option value="place-kencl">Kenmore</option>
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
