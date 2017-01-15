var $document = $(document);

$document.ready(function() {

    var $html = $('html');

    $document
        .on('click.openModal', '[data-modal]', function (e) {
            e.preventDefault();
            e.stopPropagation();
            $($(this).data('modal')).fadeIn();
            $html.addClass('_open-modal');
        })
        .on('click.closeModalByOverlay', '.modal-default', function (e) {
            if (e.target === this) {
                $(this).fadeOut();
                $html.removeClass('_open-modal');
            }
        })
        .on('click.closeModalByCloseBtn', '.modal-default__close', function (e) {
            $(this).closest('.modal-default').fadeOut();
            $html.removeClass('_open-modal');
        });

});