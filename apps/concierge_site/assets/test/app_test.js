import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';

describe("app", function() {
  let $;

  before(function() {
    window.jQuery = jsdom.rerequire('jquery');
    $ = $ || window.jQuery;
  });

  it("does not have any errors", () => {
    require('../js/app');
    assert.equal(true, true)
  });
});
