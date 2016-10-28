var NotificationSubmittingHelper = {

    Initialize: function() {
        $('form.accept-invitation').submit(function(e) {
            e.preventDefault();
            $.ajax({
                type: "post",
                url: $(this).attr('action')
            }).done(function(data) {
                $("div#invitation-" + data).hide();
            }).fail(function(data) {
                alert("Sorry, something went wrong.")
            });
        });

        $('form.reject-invitation').submit(function(e) {
            e.preventDefault();
            $.ajax({
                type: "post",
                url: $(this).attr('action')
            }).done(function(data) {
                $("div#invitation-" + data).hide();
            }).fail(function(data) {
                alert("Sorry, something went wrong.");
            });
        });
    }
}