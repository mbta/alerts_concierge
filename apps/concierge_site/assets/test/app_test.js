import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';

describe("app", function() {
  let $;

  before(function() {
    window.jQuery = jsdom.rerequire('jquery');
    $ = $ || window.jQuery;
  });

  beforeEach(function() {
    $("body").append(testHtml);
  });

  it("does not have any errors", () => {
    require('../js/app');
    assert.equal(true, true)
  });

  const testHtml = `
    <div class="subscription-step enter-trip-info">
    <form class="trip-info-form subway">
    <div class="form-group select-station">
    <label for="origin" class="station-input-label form-label">Origin</label>
    <select class="subscription-select-origin no-js" id="subscription_origin" name="subscription[origin]">
    <option value="">Select a station</option>
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
    <option value="">Select a station</option>
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
});
