import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import { simulateKeyUp, simulateKeyPress } from './utils';
import selectStation from '../js/select-station';

describe("selectCommuterRailStation", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  describe("commuter rail default destinations", () => {
    beforeEach(() => {
      $("body").append(commuterRailHtml);
      selectStation($);
    });

    afterEach(function() {
      $("body > div").remove()
    });

    it("sets the destination to South Station when a South track origin is selected", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      $originInput.val("Braintree");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "South Station")
    });

    it("sets the destination to North Station when a North track origin is selected", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      $originInput.val("Gloucester");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "North Station")
    });

    it("does nothing if South Station is selected as the origin", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      $originInput.val("South Station");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "")
    });

    it("does nothing if North Station is selected as the origin", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      $originInput.val("North Station");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "")
    });

    it("does nothing if a destination is already selected", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      $destinationInput.val("Quincy Center")
      simulateKeyUp($destinationInput[0]);
      $(".destination-station-suggestion").first().mousedown();

      $originInput.val("Braintree");
      simulateKeyUp($originInput[0]);
      $(".origin-station-suggestion").first().mousedown();

      assert.equal($destinationInput.val(), "Quincy Center")
    });
  });

  describe("select commuter rail station", () => {
    beforeEach(function() {
      $("body").append(commuterRailHtml);
      selectStation($);
    });

    afterEach(function() {
      $("body > div").remove()
    });

    it("displays line along with icon", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("Gloucester");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0]);

      const $suggestions = $(".origin-station-suggestion")
      const gloucesterSuggestion = $(".line-name", $suggestions).text();

      assert.include(gloucesterSuggestion, "Newburyport/Rockport Line");
    });

    it("starts with no value selected and data-valid false", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      assert.equal($originInput.val(), "");
      assert.equal("false", $originInput.attr("data-valid"));
      assert.equal($destinationInput.val(), "");
      assert.equal("false", $destinationInput.attr("data-valid"));
    });

    it("displays Multiple Lines along with icon when stop is a part of multiple lines", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("North");
      const $suggestionContainer = $("input.subscription-select-origin + .suggestion-container");

      simulateKeyUp($originInput[0])

      const $suggestions = $(".origin-station-suggestion")
      const northStationSuggestion = $(".line-name", $suggestions).text();

      assert.include(northStationSuggestion, "Multiple Lines");
    });
  });

  describe("keypress handling for suggestions", () => {
    beforeEach(function() {
      $("body").append(commuterRailHtml);
      selectStation($);
    });

    afterEach(function() {
      $("body > div").remove()
    });

    it("first suggestion is selected by default", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);

      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the down arrow moves the selected suggestion down to the next suggestion", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);
      simulateKeyPress($originInput[0], 40);
      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();

      assert.isFalse($firstSuggestion.is(".selected-suggestion"));
      assert($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the down arrow doesn't do anything if there aren't any more suggestions below", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);
      simulateKeyPress($originInput[0], 40);
      simulateKeyPress($originInput[0], 40);
      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();

      assert.isFalse($firstSuggestion.is(".selected-suggestion"));
      assert($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the up arrow moves the selected suggestion up to the previous suggestion", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);
      simulateKeyPress($originInput[0], 40);
      simulateKeyPress($originInput[0], 38);
      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the up arrow doesn't do anything if there aren't any more suggestions above", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);
      simulateKeyPress($originInput[0], 38);
      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing enter selects the highlighted suggestion", () => {
      const $originInput = $("input.subscription-select-origin");
      $originInput.val("tation");

      simulateKeyUp($originInput[0]);
      simulateKeyPress($originInput[0], 40);

      const $firstSuggestion = $(".origin-station-suggestion").first();
      const $lastSuggestion = $(".origin-station-suggestion").last();
      assert($lastSuggestion.is(".selected-suggestion"));

      simulateKeyPress($originInput[0], 13);

      assert.equal($originInput.val(), "South Station")
    });
  });

  describe("commuter rail prefilled", () => {
    beforeEach(function() {
      $("body").append(commuterRailHtmlWithSelections);
      selectStation($);
    });

    afterEach(function() {
      $("body > div").remove()
    });

    it("has preselected stations if origin and destination are passed to page when loading", () => {
      const $originInput = $("input.subscription-select-origin");
      const $destinationInput = $("input.subscription-select-destination");

      assert.equal($originInput.val(), "Lynn");
      assert.equal("true", $originInput.attr("data-valid"));
      assert.equal($destinationInput.val(), "North Station");
      assert.equal("true", $destinationInput.attr("data-valid"));
    });
  });

  const commuterRailHtml = `
  <div class="subscription-step enter-trip-info">
    <form accept-charset="UTF-8" action="/subscriptions/commuter_rail/new/train" class="trip-info-form commuter-rail" method="post">
      <input type="hidden" name="default-south-id" value="place-sstat">
      <input type="hidden" name="default-north-id" value="place-north">
      <input type="hidden" name="mode" value="commuter-rail">
      <div class="form-group select-station">
        <label for="origin" class="station-input-label form-label">Origin</label>
        <select class="subscription-select subscription-select-origin no-js" id="subscription_origin" name="subscription[origin]" data-valid="false">
          <option value="">Select a station</option>
          <optgroup label="Lowell Line">
            <option value="place-north">North Station</option>
          </optgroup>
          <optgroup label="Newburyport/Rockport Line">
            <option value="Gloucester">Gloucester</option>
            <option value="place-north">North Station</option>
          </optgroup>
          <optgroup label="Middleborough/Lakeville Line">
            <option value="place-brntn">Braintree</option>
            <option value="place-qnctr">Quincy Center</option>
            <option value="place-sstat">South Station</option>
          </optgroup>
        </select>
      </div>
      <div class="form-group select-station">
        <label for="destination" class="station-input-label form-label">Destination</label>
        <select class="subscription-select subscription-select-destination no-js" id="subscription_destination" name="subscription[destination]" data-valid="false">
          <option value="">Select a station</option>
          <optgroup label="Lowell Line">
            <option value="place-north">North Station</option>
          </optgroup>
          <optgroup label="Newburyport/Rockport Line">
            <option value="Gloucester">Gloucester</option>
            <option value="place-north">North Station</option>
          </optgroup>
          <optgroup label="Middleborough/Lakeville Line">
            <option value="place-brntn">Braintree</option>
            <option value="place-qnctr">Quincy Center</option>
            <option value="place-sstat">South Station</option>
          </optgroup>
        </select>
      </div>
    </form>
  </div>
  `;

  const commuterRailHtmlWithSelections = `
  <div class="subscription-step enter-trip-info">
    <form accept-charset="UTF-8" action="/subscriptions/commuter_rail/new/train" class="trip-info-form commuter-rail" method="post">
      <input type="hidden" name="default-south-id" value="place-sstat">
      <input type="hidden" name="default-north-id" value="place-north">
      <input type="hidden" name="mode" value="commuter-rail">
      <div class="form-group select-station">
        <label for="origin" class="station-input-label form-label">Origin</label>
      </div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
      <select class="subscription-select subscription-select-origin no-js" id="subscription_origin" name="subscription[origin]" data-valid="false">
        <option value="">Select a station</option>
        <optgroup label="Lowell Line">
          <option value="place-north">North Station</option>
        </optgroup>
        <optgroup label="Newburyport/Rockport Line">
          <option value="Gloucester">Gloucester</option>
          <option value="Lynn" selected="selected">Lynn</option>
          <option value="place-north">North Station</option>
        </optgroup>
        <optgroup label="Middleborough/Lakeville Line">
          <option value="place-brntn">Braintree</option>
          <option value="place-qnctr">Quincy Center</option>
          <option value="place-sstat">South Station</option>
        </optgroup>
      </select>
      <div class="form-group select-station">
        <label for="destination" class="station-input-label form-label">Destination</label>
        <div class="suggestion-container">
      </div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
      <select class="subscription-select subscription-select-destination no-js" id="subscription_destination" name="subscription[destination]" data-valid="false">
        <option value="">Select a station</option>
        <optgroup label="Lowell Line">
          <option value="place-north">North Station</option>
        </optgroup>
        <optgroup label="Newburyport/Rockport Line">
          <option value="Gloucester">Gloucester</option>
          <option value="Lynn">Lynn</option>
          <option value="place-north" selected="selected">North Station</option>
        </optgroup>
        <optgroup label="Middleborough/Lakeville Line">
          <option value="place-brntn">Braintree</option>
          <option value="place-qnctr">Quincy Center</option>
          <option value="place-sstat">South Station</option>
        </optgroup>
      </select>
    </form>
  </div>
  `;
});
