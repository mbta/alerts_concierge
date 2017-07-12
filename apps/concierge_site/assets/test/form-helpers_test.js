import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import formHelpers from '../js/form-helpers';

describe("formHelpers", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  afterEach(function() {
    $("body > div").remove()
  });

  describe("dirty inputs after focus before applying validation styling", function(){
    beforeEach(function() {
      $("body").append(textInputHtml);
      formHelpers($);
    });

    it("applies dirty class to form once focused", () => {
      const $input = $("input").first();
      assert.isFalse($input.hasClass("dirty"));
      $input.focus();
      assert.isTrue($input.hasClass("dirty"));
      $input.blur();
      assert.isTrue($input.hasClass("dirty"));
    });

    const textInputHtml = `
      <div>
        <input class="form-control" id="user_email" name="user[email]" placeholder="your@email.com" required="required" type="email">
      </div>
      `
  });
});
