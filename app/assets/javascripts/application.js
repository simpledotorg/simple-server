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

  // helper function to create nodeArrays (not collections)
  const nodeArray = (selector, parent = document) => [].slice.call(parent.querySelectorAll(selector))

  // checkboxes of interest
  const allThings = nodeArray('input.access-input', document.getElementById('facility-access'));

  // global listener
  addEventListener('change', e => {
    let check = e.target;

    //	exit if change event did not come from
    //	our list of allThings
    if (allThings.indexOf(check) === -1) return;

    //	check/uncheck children (includes check itself)
    const children = nodeArray('input.access-input', check.parentNode.parentNode);
    console.log(check.parentNode.parentNode);
    console.log(children);

    children.forEach(child => child.checked = check.checked);

    // traverse up from target check
    while (check) {

      // find parent and sibling checkboxes (quick 'n' dirty)
      const parent = (check.closest(['ul']).parentNode).querySelector('input.access-input');
      const siblings = nodeArray('input.access-input', parent.closest('li').querySelector(['ul']));

      // get checked state of siblings
      // are every or some siblings checked (using Boolean as test function)
      const checkStatus = siblings.map(check => check.checked);
      const every = checkStatus.every(Boolean);
      const some = checkStatus.some(Boolean);

      // check parent if all siblings are checked
      // set indeterminate if not all and not none are checked
      parent.checked = every;
      parent.indeterminate = !every && every !== some;

      // prepare for next loop
      check = check != parent ? parent : 0;
    }
  })

  /*
  closest polyfill for ie


  if (window.Element && !Element.prototype.closest) {
    Element.prototype.closest =
    function(s) {
      var matches = (this.document || this.ownerDocument).querySelectorAll(s),
          i,
          el = this;
      do {
        i = matches.length;
        while (--i >= 0 && matches.item(i) !== el) {};
      } while ((i < 0) && (el = el.parentElement));
      return el;
    };
  }
  */
});
