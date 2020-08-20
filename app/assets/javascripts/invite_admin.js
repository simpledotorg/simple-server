function submitForm() {
  const selectedFacilities =
    [].slice
      .call(document.querySelectorAll('input[name="facilities"]'))
      .filter(e => e.type !== "hidden" && !e.disabled && e.checked)
      .map(e => e.id)

  document.getElementById('facility-access-selections').value = JSON.stringify(selectedFacilities);
}

function toggleItemCollapsed(wrapper) {
  const collapsed = wrapper.classList.contains("collapsed")
  if (collapsed) {
    wrapper.classList.remove("collapsed")
  } else {
    wrapper.classList.add("collapsed")
  }
}

function onFacilityAccessItemToggled(event) {
  const children = Array.from(event.target.parentNode.parentNode.childNodes)
  const wrapper = children.find(item =>
    item.className === "facility-access-item-wrapper" ||
    item.className === "facility-access-item-wrapper collapsed")
  if (wrapper) {
    toggleItemCollapsed(event.target)
    toggleItemCollapsed(wrapper)
  }
}

function collapseListener() {
  const facilityAccessItems = document.getElementsByClassName("access-ratio")
  for (let item of facilityAccessItems) {
    item.addEventListener("click", onFacilityAccessItemToggled)
  }
}

function inviteAdmin() {
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
    const children = nodeArray('input.access-input', check.parentNode.parentNode.parentNode);
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
}

