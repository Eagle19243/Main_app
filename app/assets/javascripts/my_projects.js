$(document).on("click.updateProjectId", "[data-modal='#change-leader-modal']", function(e) {
    $("#project_id").val($(this).data("id"));
});