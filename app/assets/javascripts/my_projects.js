$(document).on("click.updateProjectId", "[data-modal='#change-leader-modal']", function(e) {
    var projectId = $(e.relatedTarget).data("id");
    $(this).find("#project_id").val(projectId);
});