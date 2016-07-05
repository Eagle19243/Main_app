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
     url: '/projects/' + projectId + '/save-edits',
     dataType: "json",
     method: 'POST',
     data: { project: {id: projectId, project_edit: description } }
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

#update the status of an edit via ajax
window.updateEdit = (projectEditId, new_state)->
  projectId = $("button[data-makes-editable]").data("makes-editable")
  $.ajax({
     url: '/projects/' + projectId + '/update-edits',
     dataType: "json",
     method: 'POST',
     data: { project: {id: projectId, editItem: {id: projectEditId, new_state: new_state} } }
   })
     .then (dt, textStatus, xhr)->
       console.log(dt)
       console.log(xhr.status)
       if xhr.status == 200
         deleteDiv = "project-edit-" + projectEditId
         $("#" + deleteDiv).remove()
         if new_state == "accepted"
           $("#proj-desc").text(dt.description)
         alertSuccess()

jQuery ->
 $('#project_expires_at').datepicker()
 $(document).foundation()

 #attach handlers to data attributes
 $("button[data-makes-editable]").off().on "click", (e)->
   debugger;
   e.preventDefault()
   projectId = $(this).data("makes-editable")
   makeEditable(projectId)

 $("button[data-accepts-edit]").off().on "click", (e)->
   e.preventDefault()
   projectEditId = $(this).data("accepts-edit")
   updateEdit(projectEditId, "accepted")

 $("button[data-rejects-edit]").off().on "click", (e)->
   e.preventDefault()
   projectEditId = $(this).data("rejects-edit")
   updateEdit(projectEditId, "rejected")

  $(document).on 'page:load', ->
       console.log( "readyp!" )
       #attach handlers to data attributes
       $("button[data-makes-editable]").off().on "click", (e)->
         e.preventDefault()
         projectId = $(this).data("makes-editable")
         makeEditable(projectId)

       $("button[data-accepts-edit]").off().on "click", (e)->
         e.preventDefault()
         projectEditId = $(this).data("accepts-edit")
         updateEdit(projectEditId, "accepted")

       $("button[data-rejects-edit]").off().on "click", (e)->
         e.preventDefault()
         projectEditId = $(this).data("rejects-edit")
         updateEdit(projectEditId, "rejected")
