// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.jcrop
//= require jquery_ujs
//= require autocomplete-rails
//= require jquery.remotipart
//= require best_in_place
//= require bootstrap-sprockets
//= require foundation
//= require foundation-datetimepicker
//= require chosen-jquery
//= require jquery-ui/datepicker
//= require tinymce-jquery
//= require social-share-button
//= require react
//= require react_ujs
//= require components
//= require zeroclipboard
//= require jquery-ui
//= require jquery.purr
//= require best_in_place.purr
//= require jquery.validate.min
//= require jquery.slimscroll
//= require cocoon
//= require bootstrap-sprockets
//= require jquery.slick
//= require jquery.vcarousel-min
//= require underscore-min
//= require moment
//= require bootstrap-datetimepicker

//= require_tree .

var $document = $(document);
var $html = $('html');
$document.foundation();

$document.on('page:load', function() {
  $document.foundation();
});

$(function() {
  $('img').one('error', function() {
    this.src = '/assets/no_image.png';
  });
  $('.task-box').matchHeight();
  $document.foundation();
});

$(function() {
  $('.task-box').matchHeight();
});


var TabsModule = (function () {

    function bindEvents($document) {
        $document
            .on('click.changeTab', '.m-tabs__link', function (e) {
                e.preventDefault();
                e.stopPropagation();
                var $that = $(this), taskId,
                    tab = $that.data('tab'),
                    paramsArr = window.location.search.slice(1).split('&');
                UrlModule.setTab(tab);
                $document.find('.tabcontent').hide();
                $document.find('.m-tabs__link').removeClass('active');
                document.getElementById(tab).style.display = "block";
                $that.addClass('active');
                $('#sourceEditor').hide();
                tab === "Team" ? $('.get-invo-btn').show() : $('.get-invo-btn').hide();
                paramsArr.map(function (item) {
                    if (item.indexOf('taskId=') === 0) {
                        taskId = item.split('=')[1];
                    }
                });
                window.history.pushState(null, null, window.location.pathname + ('?tab=' + (taskId ? 'Tasks&taskId=' + taskId : tab)));
            });
    }

    return {
        init: function ($document) {
            bindEvents($document);
        }
    };
})();

var ModalsModule = (function () {

    var modalsArr = ["#team", "#suggested_task_popup", "#myModal2", ".modal-default", "#popup-for-free-paid", "#modalVerification", "#registerModal"]; // todo try to remove this

    function openModal(modalSelector) {
        $(modalSelector).fadeIn();
        $html.addClass('_open-modal');
    }

    function togglePreloader(isShow) {
        if (typeof(isShow) === "boolean") {
            return isShow ? $('#loading-mask1').show() : $('#loading-mask1').hide();
        }
        $('#loading-mask1').fadeToggle();
    }

    function bindEvents($document) {
        $document
            .on('click.openModal', '[data-modal]', function (e) {
                e.preventDefault();
                e.stopPropagation();
                $($(this).data('modal')).fadeIn();
                $html.addClass('_open-modal');
            })
            .on('click.closeModalByOverlay', '.modal-default', function (e) {
                if (e.target !== this) return;
                $(this).fadeOut();
                $html.removeClass('_open-modal');
            })
            .on('click.closeModalByCloseBtn', '.modal-default__close, [data-modal-close]', function (e) {
                $(this).closest('.modal-default').fadeOut();
                $html.removeClass('_open-modal');
            })
            .on('click.closeTaskModalByBtn', '#task-popup-close', function (e) {
                UrlModule.closeTaskModal();
            })
            .on('click.closeTaskModalByOverlay', '#myModal', function (e) {
                if (e.target === this) UrlModule.closeTaskModal();
            })
            .on('keydown.closeModals', function (e) {
                if (e.keyCode == 27) {  // todo rewrite when be removed modalsArr
                    for (var i = 0, max = modalsArr.length; i < max; i++) {
                        $(modalsArr[i]).fadeOut();
                    }
                    $('.modal-backdrop').remove();
                    $html.removeClass('_open-modal');
                }
            });
    }

    return {
        init: function ($document) {
            bindEvents($document);
        },
        openModal: function (modalSelector) {
          openModal(modalSelector);
        },
        togglePreloader: function (isShow) {
            togglePreloader(isShow);
        }
    };
})();

var UrlModule = (function () {

    var paramsArr, taskId, isAlreadyCheckedTaskModal, isAlreadyCheckedTab, tab, isCardClicked;

    function bindEvents($document) {
        $document
            .on('click.changeUrlTaskModal', '.pr-card', function () {
                if (isCardClicked) return;
                var taskId = $(this).data('taskId');
                ModalsModule.togglePreloader(true);
                window.history.pushState(null, null, window.location.pathname + '?tab=' + tab + '&taskId=' + taskId);
                isCardClicked = true;
            });
    }

    function checkIsCardClicked() {
        return isCardClicked;
    }

    function enableCardClick() {
        isCardClicked = false;
    }

    function getTaskParam() {
        return taskId;
    }

    function setTab(newTab) {
        tab = newTab;
    }

    function closeTaskModal() {
        window.history.pushState(null, null, window.location.pathname + '?tab=' + tab);
        taskId = null;
    }

    function checkTaskModal() {
        if (isAlreadyCheckedTaskModal) return;
        for (var i = 0; i < paramsArr.length; i++) {
            if (paramsArr[i].indexOf('taskId=') === 0) {
                if (isCardClicked) return;
                taskId = paramsArr[i].split('=')[1];
                ModalsModule.togglePreloader(true);
                $('[data-task-id="' + taskId + '"]').trigger('click');
                break;
            }
        }
        isAlreadyCheckedTaskModal = true;
    }

    function checkTabModal() {
        if (isAlreadyCheckedTab) return;
        for (var i = 0; i < paramsArr.length; i++) {
            if (paramsArr[i].indexOf('tab=') === 0) {
                tab = paramsArr[i].split('=')[1];
                $('[data-tab="' + tab + '"]').trigger('click');
                break;
            }
        }
        if (!tab) $('[data-tab="Plan"]').trigger('click');
        isAlreadyCheckedTab = true;
    }

    function checkUrl() {
        paramsArr = window.location.search.slice(1).split('&');
        checkTabModal();
        checkTaskModal();
    }

    return {
        init: function ($document) {
            bindEvents($document);
            setTimeout(function () {
                checkUrl();
            }, 0);
        },
        checkUrl: function () {
            checkUrl();
        },
        getTaskParam: function () {
            return getTaskParam();
        },
        closeTaskModal: function () {
            closeTaskModal();
        },
        setTab: function (tab) {
            setTab(tab);
        },
        enableCardClick: function () {
            enableCardClick();
        },
        checkIsCardClicked: function () {
            return checkIsCardClicked();
        }
    };
})();

$document.ready(function() {
    $(".best_in_place").best_in_place();

    UrlModule.init($document);
    ModalsModule.init($document);
    TabsModule.init($document);
});

// enhance Turbolinks when necessary
// https://coderwall.com/p/ii0a_g/page-reload-refresh-every-5-sec-using-turbolinks-js-rails-jquery
// this code may be removed without harmful side effects
// https://engineering.onlive.com/2014/02/14/turbolinks-the-best-thing-you-wont-ever-use-in-rails-4/
// $(document).on('ready page:load', function() {
//     var REFRESH_INTERVAL_IN_MILLIS = 5000;
//      if ($('.f-pending-message').length >= 0) {
//        setTimeout(function(){
//         //disable page scrolling to top after loading page content
//         Turbolinks.enableTransitionCache(true);
//
//         // pass current page url to visit method
//         Turbolinks.visit(location.toString());
//
//         //enable page scroll reset in case user clicks other link
//         Turbolinks.enableTransitionCache(false);
//          }, REFRESH_INTERVAL_IN_MILLIS);
//     }
// });
