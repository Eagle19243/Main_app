var NotificationSubmittingHelper = {

    Initialize: function() {
        initializeInvitationsControls();
        initializeRequestsControls();
    }
}

function initializeInvitationsControls() {
    initializeNotificationFormControl("form.reject-invitation", "div#invitation-");
    initializeNotificationFormControl("form.accept-invitation", "div#invitation-");
    // $('form.accept-invitation').submit(function(e) {
    //     e.preventDefault();
    //     $.ajax({
    //         type: "post",
    //         url: $(this).attr('action')
    //     }).done(function(data) {
    //         debugger;
    //         $("div#invitation-" + data).hide();
    //     }).fail(function(data) {
    //         debugger;
    //         alert("Sorry, something went wrong.")
    //     });
    // });
    //
    // $('form.reject-invitation').submit(function(e) {
    //     e.preventDefault();
    //     $.ajax({
    //         type: "post",
    //         url: $(this).attr('action')
    //     }).done(function(data) {
    //         $("div#invitation-" + data).hide();
    //     }).fail(function(data) {
    //         alert("Sorry, something went wrong.");
    //     });
    // });
}

function initializeRequestsControls() {
    // $('form.accept-request').submit(function(e) {
    //     e.preventDefault();
    //     $.ajax({
    //         type: "post",
    //         url: $(this).attr('action')
    //     }).done(function(data) {
    //         debugger;
    //         $("div#request-" + data).hide();
    //     }).fail(function(data) {
    //         debugger;
    //         alert("Sorry, something went wrong.")
    //     });
    // });
    //
    // $('form.reject-request').submit(function(e) {
    //     e.preventDefault();
    //     $.ajax({
    //         type: "post",
    //         url: $(this).attr('action')
    //     }).done(function(data) {
    //         $("div#request-" + data).hide();
    //     }).fail(function(data) {
    //         alert("Sorry, something went wrong.");
    //     });
    // });
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