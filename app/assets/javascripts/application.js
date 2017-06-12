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

var DateTimePickerModule = (function () {

    function bindEvents() {
        var DAY_TO_DEADLINE = 89,
            currentDate = new Date(),
            deadlineDate = new Date().setDate(currentDate.getDate() + DAY_TO_DEADLINE);

        $('.deadline_picker').datetimepicker({
            viewMode: 'months',
            format: 'YYYY-MM-DD HH:mm A',
            minDate: currentDate,
            maxDate: deadlineDate
        });
    }

    return {
        init: function ($document) {
            bindEvents($document);
        }
    };
})();


var TabsModule = (function () {

    function bindEvents($document) {
        $document
            .on('click.changeTab', '.m-tabs__link', function (e) {
                e.preventDefault();
                e.stopPropagation();
                var $that = $(this), taskId,
                    $html = $('html'),
                    tab = $that.data('tab'),
                    paramsArr = window.location.search.slice(1).split('&');
                UrlModule.setTab(tab);
                $document.find('.tabcontent').hide();
                $document.find('.m-tabs__link').removeClass('active');
                $('.tabs-wrapper__' + tab).show();
                $that.addClass('active');
                $('#sourceEditor').hide();
                tab === "team" ? $('.get-invo-btn').show() : $('.get-invo-btn').hide();
                paramsArr.map(function (item) {
                    if (item.indexOf('taskId=') === 0) {
                        taskId = item.split('=')[1];
                    }
                });

                if ($html.hasClass('_open-modal')) {
                    $('#welcomeToTeamModal').fadeOut(300);
                    setTimeout(function () {
                        $html.removeClass('_open-modal');
                        if ($that.data('tab') === 'tasks') {
                            $('#tab-tasks').addClass('active');
                        } else {
                            $('#tab-plan').addClass('active');
                        }
                    }, 300)
                }
                if (LanguageModule.isLanguageSet()) {
                    window.history.pushState(null, null, window.location.pathname + ('?tab=' + (taskId ? 'Tasks&taskId=' + taskId : tab)) + '&locale=' + LanguageModule.getCurrentLanguage());
                } else {
                    window.history.pushState(null, null, window.location.pathname + ('?tab=' + (taskId ? 'Tasks&taskId=' + taskId : tab)));
                }
            });
    }

    return {
        init: function ($document) {
            bindEvents($document);
        }
    };
})();

var RevisionModule = (function() {
    function bindEvents($document) {
        $document
            .on('click.blockUser', '.revision-status-btn', function(e) {
                e.preventDefault();

                var $that = $(this),
                    projectId = $that.data('project-id'),
                    username = $that.data('username'),
                    url = LanguageModule.isLanguageSet() ? '/projects/' + projectId + ($that.hasClass('_block-user') ? '/block_user?username=' : '/unblock_user?username=') + username:
                                                            '/projects/' + projectId + ($that.hasClass('_block-user') ? '/block_user?username=' : '/unblock_user?username=') + username + '&locale=' + LanguageModule.getCurrentLanguage();

                sessionStorage.setItem('revisionBlockOpen', JSON.stringify(true));

                window.location.assign(window.location.origin + url);
            })
    }
    function checkVisibilityRevisionBlock() {
        if (JSON.parse(sessionStorage.getItem('revisionBlockOpen'))) {
            setTimeout(function () {
                $('#editSource').click();
            });
            sessionStorage.removeItem('revisionBlockOpen');
        }
    }
    return {
        init: function ($document) {
            bindEvents($document);
            checkVisibilityRevisionBlock();
        }
    };
})();

var ModalsModule = (function () {

    var modalsArr = ["#team", "#suggested_task_popup", "#share", "#myModal2", ".modal-default", "#popup-for-free-paid", "#modalVerification", "#registerModal"]; // todo try to remove this

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
                var hideModal = true;
                $(this).closest('.modal-default').fadeOut(400, function() {
                    $('.modal-default').each(function(index, element) {
                        if ($(element).is(':visible')) {
                            hideModal = false;
                        }
                    });

                    if (hideModal) {
                        $html.removeClass('_open-modal');
                    }
                });

            })
            .on('click.closeTaskModalByBtn', '#task-popup-close', function (e) {
                UrlModule.closeTaskModal();
            })
            .on('click.closeTaskModalByOverlay', '#myModal', function (e) {
                if (e.target === this) UrlModule.closeTaskModal();
            })
            .on('keydown.closeModals', function (e) {
                if (e.keyCode === 27) {  // todo rewrite when be removed modalsArr
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

var LanguageModule = (function() {

    function _insertCurrentFlag(svg) {
        $('.s-header__lang-select').html(svg);
    }
    
    function _getCurrentSvgFlag(flagName) {
        return '' +
            '<svg focusable="false" version="1.1" class="svg-' + flagName + '-flag" aria-hidden="true">' +
                '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#svg-' + flagName + '-flag"></use>' +
            '</svg>'
    }

    function _getCurrentLanguage() {
        return location.href.split('locale=')[1]
    }

    function _isLanguageSet() {
        return location.href.indexOf('locale=') >= 0;
    }

    function detectCurrentLanguage() {
        switch (location.href.split('locale=')[1]) {
            case 'en':
                _insertCurrentFlag(_getCurrentSvgFlag('uk'));
                break;
            case 'es':
                _insertCurrentFlag(_getCurrentSvgFlag('spain'));
                break;
            default: 
                _insertCurrentFlag(_getCurrentSvgFlag('uk'));
                break;
        }
    }

    function bindEvents($document) {
        $(document).ready(function() {
            detectCurrentLanguage();
        })
    }
    return {
        init: function($document) {
            bindEvents($document);
        },
        isLanguageSet: _isLanguageSet,
        getCurrentLanguage : _getCurrentLanguage
    }
})();

var ProjectAndTaskSearchModule = (function() {
    function bindEvents($document) {
        $document
            .on('input.userSearch', '#userSearchTasksAndProject', $.debounce(250, function () {
                var $this = $('#userSearchTasksAndProject'),
                    searchValue = $this.val(),
                    $searchResultsList = $('.search-result__list');

                $.ajax({
                    url: '/projects/autocomplete_user_search?term=' + searchValue,
                    type: 'GET',
                    dataType: 'json',
                    success: function (response) {
                        var results = '';

                        response.forEach(function(item) {
                            results += '<li class="search-result__item"><a href="' + item.path + '">' + item.title + '</a></li>';
                        });
                        $searchResultsList.html(results);
                    }
                })
            }))
    }

    return {
        init: function($document) {
            bindEvents($document);
        }
    }
})();

var UrlModule = (function () {

    var paramsArr, taskId, isAlreadyCheckedTaskModal, isAlreadyCheckedTab, tab, isCardClicked;

    function bindEvents($document) {
        $document
            .on('click.changeUrlTaskModal', '.pr-card', function () {
                if (isCardClicked) return;
                var taskId = $(this).data('taskId');
                ModalsModule.togglePreloader(true);

                if (LanguageModule.isLanguageSet()) {
                    window.history.pushState(null, null, window.location.pathname + '?tab=' + tab + '&taskId=' + taskId + '&locale=' + LanguageModule.getCurrentLanguage());
                } else {
                    window.history.pushState(null, null, window.location.pathname + '?tab=' + tab + '&taskId=' + taskId);
                }
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

        if (LanguageModule.isLanguageSet()) {
            window.history.pushState(null, null, window.location.pathname + '?tab=' + tab + '&locale=' + LanguageModule.getCurrentLanguage());
        } else {
            window.history.pushState(null, null, window.location.pathname + '?tab=' + tab);
        }
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
        if (!tab) $('[data-tab="plan"]').trigger('click');
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

    ProjectAndTaskSearchModule.init($document);
    DateTimePickerModule.init($document);
    UrlModule.init($document);
    LanguageModule.init($document);
    ModalsModule.init($document);
    TabsModule.init($document);
    RevisionModule.init($document);
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
