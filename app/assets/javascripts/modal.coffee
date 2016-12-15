
$().ready ->
  $(document).on 'click', '#myModalclose', ->
    $(document).find('#myModal').hide()
