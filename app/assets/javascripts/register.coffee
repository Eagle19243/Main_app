$(document).ready ->
  $document = $(document)
  $modalSign = $('.modal-sign')

  showSignIn = () ->
    $modalSign.addClass('_sign-in').removeClass('_sign-up')
  showSignUp = () ->
    $modalSign.addClass('_sign-up').removeClass('_sign-in')

  $document.on 'click.showSignIn', '.sign_in_a', () ->
    showSignIn()
    return

  $document.on 'click.showSignUp', '.sign_up_a', () ->
    showSignUp()
    return

  $document.on 'click.startProject', '#start_project_link', () ->
    $modalSign.removeClass('_sign-in').removeClass('_sign-up')
    localStorage.setItem 'start_project', true
    return

  return