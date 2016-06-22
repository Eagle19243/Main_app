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
//= require jquery_ujs
//= require foundation
//= require foundation-datetimepicker
//= require chosen-jquery
//= require scaffold
//= require jquery-ui/datepicker
//= require tinymce-jquery
//= require social-share-button
//= require turbolinks
//= require react
//= require react_ujs
//= require components
//= require_tree .
// $(function() {
//   $(document).foundation();
// });
// http://stackoverflow.com/questions/25150922/trouble-using-foundation-and-turbolinks-with-rails-4
$(document).foundation();

$(document).off('page:load').on('page:load', function() {
    console.log( "ready!" );
    $(document).foundation();
});
