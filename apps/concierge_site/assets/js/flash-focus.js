export default $ => {
  $ = $ || window.jQuery;

  // Focus flash banners
  $(".alert.alert-success").focus();
  $(".error-block-container").focus();
};
