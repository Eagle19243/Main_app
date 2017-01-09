
$().ready ->
  $('#sign_in_a ,#sign_in_nav').click ->
    $('.sign_up_show').hide()
    $('.sign_in_show').show()
    $('.start_project_show').hide()
    return

  $('#sign_up_a, #sign_up_nav').click ->
    $('.sign_in_show').hide()
    $('.sign_up_show').show()
    $('.start_project_show').hide()
    return

  $('#start_project_link').click ->
    $('.sign_in_show').hide()
    $('.sign_up_show').hide()
    $('.start_project_show').show()
    $('#sign_up_email').show()
    localStorage.setItem 'start_project', true
    return

  $('#sign_up_email').click ->
    $('.sign_up_show').show()
    $('.sign_in_show').hide()
    $('.start_project_show').hide()
    $('#sign_up_email').hide()
    return

  $(document).on 'click', '#sign_in_link', (e) ->
    $('.sign_up_show').hide()
    $('.sign_in_show').show()
    $('.start_project_show').hide()
    return
