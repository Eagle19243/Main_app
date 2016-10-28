var NotificationSubmittingHelper = {

    Initialize: function() {
        debugger;
        $('form.accept-invitation').submit(function(e) {
            debugger;
            e.preventDefault();
            $.ajax({
                type: "post",
                url: $(this).attr('action')
            }).done(function(data) {
                alert("Accepted");
            }).fail(function(data) {
                alert("Sorry, something went wrong.")
            });
        });

        $('form.reject-invitation').submit(function(e) {
            debugger;
            e.preventDefault();
            $.ajax({
                type: "post",
                url: $(this).attr('action')
            }).done(function(data) {
                alert("Rejected");
            }).fail(function(data) {
                alert("Sorry, something went wrong.");
            });
        });
    }
}