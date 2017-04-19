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

$(document).ready ->
  if JSON.parse(sessionStorage.getItem('showMessageAfterRegister'))
    show_ajax_message('A message with a confirmation link has been sent' +
                      ' to your email address. Please follow the link to' +
                      ' activate your account.', 'success')
    sessionStorage.removeItem('showMessageAfterRegister')

  if sessionStorage.getItem('showMessageAfterSignedIn')
    show_ajax_message('Signed in successfully.', 'success')
    sessionStorage.removeItem('showMessageAfterSignedIn')

$(document).ajaxComplete (event, request) ->
  messages = jQuery.parseJSON(request.getResponseHeader("X-Messages"))

  $.each messages, (type, msg) ->
    setTimeout( ->
      show_ajax_message(msg, type)
      return
    )
