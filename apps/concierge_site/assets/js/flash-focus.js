import $ from "jquery";

export default () => {
  // Focus flash banners
  $(".alert.alert-success").focus();
  $(".error-block-container").focus();
};
