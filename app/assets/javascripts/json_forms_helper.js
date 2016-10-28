var JsonFormsHelper = {
    InitializeNotificationsControls: function() {
        initializeInvitationsControls();
        initializeRequestsControls();
    },
    
    InitializeAdminRequestsControls: function() {
        initializeAdminRequestControls();
    },

    InitializeAdminInvitationsControls: function() {
        initialAdminInvitationsControls();
    }
}

function initialAdminInvitationsControls() {
    $('form.new_admin_invitation').submit(function(e) {
        e.preventDefault();
        $.ajax({
            type: $(this).attr('method'),
            url: $(this).attr('action'),
            data: $(this).serialize()
        }).done(function(data) {
            $("#invite-" + data.user_id).hide();
        }).fail(function(data) {
            alert("Sorry, something went wrong.")
        });
    });
}

function initializeAdminRequestControls() {
    $('form.new_admin_request').submit(function (e) {
        e.preventDefault();
        $.ajax({
            type: $(this).attr('method'),
            url: $(this).attr('action'),
            data: $(this).serialize()
        }).done(function (data) {
            $("#admin_requst").hide();
        }).fail(function (data) {
            alert("Sorry, something went wrong.")
        });
    });
}

function initializeInvitationsControls() {
    initializeNotificationFormControl("form.reject-invitation", "div#invitation-");
    initializeNotificationFormControl("form.accept-invitation", "div#invitation-");
}

function initializeRequestsControls() {
    initializeNotificationFormControl("form.reject-request", "div#request-");
    initializeNotificationFormControl("form.accept-request", "div#request-");
}

function initializeNotificationFormControl(formSelector, formParentSelector) {
    $(formSelector).submit(function(e) {
        e.preventDefault();
        $.ajax({
            type: "post",
            url: $(this).attr('action')
        }).done(function(data) {
            $(formParentSelector + data).hide();
        }).fail(function(data) {
            alert("Sorry, something went wrong.")
        });
    });
}
