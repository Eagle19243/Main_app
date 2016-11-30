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
//= require jquery.remotipart
//= require best_in_place
//= require bootstrap-sprockets
//= require foundation
//= require foundation-datetimepicker
//= require chosen-jquery
//= require scaffold
//= require jquery-ui/datepicker
//= require tinymce-jquery
//= require social-share-button
//= require react
//= require react_ujs
//= require components
//= require zeroclipboard
//= require jquery-ui
//= require best_in_place.jquery-ui
//= require jquery.validate.min
//= require jquery.slimscroll
//= require cocoon
//= require bootstrap-sprockets
//= require jquery.slick

//= require_tree .
// $(function() {
//   $(document).foundation();
// });
// http://stackoverflow.com/questions/25150922/trouble-using-foundation-and-turbolinks-with-rails-4

$(document).foundation();

$(document).on('page:load', function() {
  $(document).foundation();
});

$(function() {
  $('img').one('error', function() {
    this.src = '/assets/no_image.png';
  });
  $('.task-box').matchHeight();
  $(document).foundation();
});

$(function() {
  $('.task-box').matchHeight();
});

$(document).ready(function() {
  $(".best_in_place").best_in_place();
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




