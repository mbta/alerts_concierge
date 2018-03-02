export default ($) => {
  $ = $ || window.jQuery;

  const setMessageDisplay = (messageId, style) => $(`div[data-message-id='${messageId}']`).css({display: style});

  // hide all help messages
  $("div[data-type='help-message']").each(function() {
    $(this).css({display: "none"});
  });

  // show all close buttons, attach event
  $("a[data-type='close-help-text']").each(function() {
    const $link = $(this);

    $link.css({display: "inline-block"})
    .click(e => {
      e.preventDefault();
      setMessageDisplay($link.data("message-id"), "none");
    });
  });

  // show all help links, attach event
  $("a[data-type='help-link']").each(function() {
    const $link = $(this);

    $link.css({display: "inline-block"})
    .click(e => {
      e.preventDefault();
      setMessageDisplay($link.data("message-id"), "block");
    });
  });
};
