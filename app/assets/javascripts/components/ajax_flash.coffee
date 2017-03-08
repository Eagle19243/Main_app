show_ajax_message = (msg, type) ->
  flash = "<div class='flash-messages'><div data-alert class='alert-box #{type}'><div>#{msg}</div><a href='#' class='close'>&times;</a></div></div>"
  if $('.flash-messages').length > 0
    $('.flash-messages').replaceWith(flash)
  else
    $(flash).insertAfter '.header-container.s-header'
  $ ->
    setTimeout (->
      $('.alert-box').fadeOut 3000, 0
      return
    ), 15000
    return
  return

$(document).ajaxComplete (event, request) ->
  msg = request.getResponseHeader("X-Message")
  type = request.getResponseHeader("X-Message-Type")
  show_ajax_message(msg, type)
