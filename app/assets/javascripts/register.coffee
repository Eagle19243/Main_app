$(document).ready ->
  $modalSign = $('.modal-sign');
  $('#sign_in_a ,#sign_in_nav').click ->
    $modalSign.addClass('_sign-in').removeClass('_sign-up')
    return

  $('#sign_up_a, #sign_up_nav').click ->
    $modalSign.addClass('_sign-up').removeClass('_sign-in')
    return

  $('#start_project_link').click ->
    $modalSign.removeClass('_sign-in').removeClass('_sign-up')
    localStorage.setItem 'start_project', true
    return

  $('#sign_up_email').click ->
    $modalSign.addClass('_sign-up').removeClass('_sign-in')
    return

  $(document).on 'click', '#sign_in_link', () ->
    $modalSign.addClass('_sign-in').removeClass('_sign-up')
    return
  return