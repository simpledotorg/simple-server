function submitForm() {
  const selectedFacilityIds =
    [].slice
      .call(document.querySelectorAll('input[name="facilities"]'))
      .filter(e => e.type !== "hidden" && !e.disabled && e.checked)
      .map(e => e.id)

  const hiddenSelectionsField = document.getElementById('facility-access-selections')
  hiddenSelectionsField.id = null

  // Clone the hidden selection field for each selectedFacilityIds and replace value with id
  for (const id of selectedFacilityIds) {
    const clonedHiddenInput = hiddenSelectionsField.cloneNode(true)
    clonedHiddenInput.value = id
    hiddenSelectionsField.parentNode.insertAdjacentElement("beforeend", clonedHiddenInput)
  }
  hiddenSelectionsField.remove()
}

function toggleItemCollapsed(element) {
  const collapsed = element.classList.contains("collapsed")
  if (collapsed) {
    element.classList.remove("collapsed")
  } else {
    element.classList.add("collapsed")
  }
}

function onFacilityAccessItemToggled({ target }) {
  const children = Array.from(target.closest("li").childNodes)
  const wrapper = children.find(item =>
    item.className === "facility-access-item-wrapper" ||
    item.className === "facility-access-item-wrapper collapsed")
  if (wrapper) {
    toggleItemCollapsed(target)
    toggleItemCollapsed(wrapper)
  }
}

function collapseListener() {
  const facilityAccessItems = document.getElementsByClassName("access-ratio")
  for (const item of facilityAccessItems) {
    item.addEventListener("click", onFacilityAccessItemToggled)
  }
}

// helper function to create nodeArrays (not collections)
const nodeListToArray = (selector, parent = document) =>
  [].slice.call(parent.querySelectorAll(selector))

function updateParentCheckedState(element, selector) {
  // find parent and sibling checkboxes
  const parent = (element.closest(['ul']).parentNode).querySelector(selector);
  const siblings = nodeListToArray(selector, parent.closest('li').querySelector(['ul']));

  // get checked state of siblings
  // are every or some siblings checked (using Boolean as test function)
  const checkStatus = siblings.map(check => check.checked);
  const every = checkStatus.every(Boolean);
  const some = checkStatus.some(Boolean);

  // check parent if all siblings are checked
  // set indeterminate if not all and not none are checked
  parent.checked = every;
  parent.indeterminate = !every && every !== some;

  // recurse until check is the top most parent
  if (element != parent) updateParentCheckedState(parent, selector)
}

function updateChildrenCheckedState(parent, selector) {
  //	check/uncheck children (includes check itself)
  const children = nodeListToArray(selector, parent.closest("li"));
  children.forEach(child => {
    // Reset indeterminate state for children
    child.indeterminate = false
    child.checked = parent.checked
  });
}

function inviteAdmin() {
  const SELECTOR = 'input.access-input';
  const facilityAccessDiv = document.getElementById('facility-access')

  // List of all checkboxes under #facility-access
  const checkboxes = nodeListToArray(SELECTOR, facilityAccessDiv);

  addEventListener('change', e => {
    const targetCheckbox = e.target;

    // exit if change event did not come from list of checkboxes
    if (checkboxes.indexOf(targetCheckbox) === -1) return;
    updateChildrenCheckedState(targetCheckbox, SELECTOR)
    updateParentCheckedState(targetCheckbox, SELECTOR)
  })
}
