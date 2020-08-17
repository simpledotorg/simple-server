// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require bs-custom-file-input.js
//= require bs-file-input-init.js
//= require react
//= require react_ujs
//= require react-checkbox-tree
//= require lodash
//= require components
//= require tablesort
//= require tablesort/dist/sorts/tablesort.number.min
//= require teleconsultation-fields
//= require_tree .

$(function () {
  $('[data-toggle="tooltip"]').tooltip()

  if($('#analytics-table').length) {
    new Tablesort(document.getElementById('analytics-table'), { descending: true })
  }
});
