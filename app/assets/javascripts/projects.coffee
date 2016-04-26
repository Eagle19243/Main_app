# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.root = 'http://jsonplaceholder.typicode.com';

window.alertSuccess =->
  editSuccessHtml = '<div id="editAlert" data-alert class="alert-box info radius">
    You\'ve successfuly edited the project description.
    <a onClick="closeEditAlert();" class="close">&times;</a>
  </div>'
  $("div[data-edit-alert]").append(editSuccessHtml)


window.saveEdit = (projectId)->
  alert("running saveEdit")
  console.log "this saves the edit"
  #send an ajax call with the data, the call should be an edit, for a project description
  #set the button to initial state
  $("#proj-desc").attr("contenteditable", false)
  $("#editBtn").css("color", "").css("background", "").text("Edit")
  $("#editBtn").off().on "click", (e)->
    e.preventDefault()
    makeEditable()
  $.ajax({
     #url: root + '/posts/1',
     url: /projects/ + projectId,
     method: 'GET'
   })
     .then (data)->
       alertSuccess()
       console.log(data);

window.closeEditAlert=->
  $("#editAlert").remove()
  false

# makes the project description editable
window.makeEditable = (projectId)->
  $("#proj-desc").attr("contenteditable", true)
  $("#editBtn").css("color", "white").css("background", "orange").text("Save")
  console.log "project description editable"
  $("#editBtn").off().on "click", (e)->
    e.preventDefault()
    saveEdit(projectId)

jQuery ->
 $('#project_expires_at').datepicker()


 #attach handlers to data attributes
 $("button[data-makes-editable]").off().on "click", (e)->
   e.preventDefault()
   projectId = $(this).data("makes-editable")
   console.log "edits: "
   console.log projectId
   console.log "clicked on the make editable button"
   makeEditable(projectId)

 $.ajax({
    url: root + '/posts/1',
    method: 'GET'
  })
    .then (data)->
      console.log(data);
