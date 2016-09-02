$(document).ready(function () {
  var height1 = $('.invitations').height();
  var height2 = $('body').height();

  $('.reply-form .reply-field').keydown(function(e) {
    if (e.keyCode == 13) {
      $(this).closest('form').submit();
    }
  });

  if (height1 > height2) {
    console.log(height1)
    $('.sidebar').height(height1 + 50);
    $('.notifications').height(height1 + 50);
  } else {
    $('.sidebar').height(height2);
    $('.notifications').height(height2);
  }
});
