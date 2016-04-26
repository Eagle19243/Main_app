# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.alertSuccess =->
  editSuccessHtml = '<div id="editAlert" data-alert class="alert-box info radius">
    You\'ve successfuly edited the project description.
    <a onClick="closeEditAlert();" class="close">&times;</a>
  </div>'
  $("div[data-edit-alert]").append(editSuccessHtml)


window.saveEdit = (projectId)->
  $("#proj-desc").attr("contenteditable", false)
  $("#editBtn").css("color", "").css("background", "").text("Edit")
  $("#editBtn").off().on "click", (e)->
    e.preventDefault()
    makeEditable()
  description = $("#proj-desc").text()
  $.ajax({
     url: '/projects/' + projectId,
     dataType: "json",
     method: 'PUT',
     data: { project: {id: projectId, description: description} }
   })
     .then (data)->
       alertSuccess()

window.closeEditAlert=->
  $("#editAlert").remove()
  false

# makes the project description editable
window.makeEditable = (projectId)->
  $("#proj-desc").attr("contenteditable", true)
  $("#editBtn").css("color", "white").css("background", "orange").text("Save")
  $("#editBtn").off().on "click", (e)->
    e.preventDefault()
    saveEdit(projectId)

jQuery ->
 $('#project_expires_at').datepicker()


 #attach handlers to data attributes
 $("button[data-makes-editable]").off().on "click", (e)->
   e.preventDefault()
   projectId = $(this).data("makes-editable")
   makeEditable(projectId)
