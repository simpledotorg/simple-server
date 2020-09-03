const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const facilityAccessDiv = () => document.getElementById("facility-access")
const selectAllDiv = () => document.getElementById("select_all_facilities")

//
// loads at page refresh
//
window.addEventListener("DOMContentLoaded", inviteAdmin);
window.addEventListener("DOMContentLoaded", editAdmin);

function inviteAdmin() {
  selectAccessLevels()
  selectAllListener()
  checkboxItemListener()
  resourceRowCollapseListener()
}

function editAdmin() {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())
  const checkedCheckboxes = checkboxes.filter(check => check.checked)

  for (const checkbox of checkedCheckboxes) {
    updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
  }

  selectAllDiv().checked = checkboxes.every(checkbox => checkbox.checked)
}

//
// listeners
//
function selectAllListener() {
  if (!selectAllDiv()) return

  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())

  selectAllDiv().addEventListener("change", () => {
    for (const checkbox of checkboxes) {
      checkbox.checked = selectAllDiv().checked
    }
  })
}

function checkboxItemListener() {

  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())

  addEventListener("change", e => {
    const targetCheckbox = e.target

    // exit if change event did not come from list of checkboxes
    if (checkboxes.indexOf(targetCheckbox) === -1) return
    updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
    updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
  })
}

function resourceRowCollapseListener() {
  const facilityAccessItems = document.getElementsByClassName("access-ratio")

  for (const item of facilityAccessItems) {
    item.addEventListener("click", onFacilityAccessItemToggled)
  }
}

//
// behaviour
//

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
  const parentItem = target.closest(".access-item")
  const wrapper = children.find(function (item) {
    return item.className === "access-item-wrapper" ||
      item.className === "access-item-wrapper collapsed" ||
      item.className === "access-item-wrapper facility" ||
      item.className === "access-item-wrapper facility collapsed" ||
      item.className === "access-item-wrapper facility-group collapsed" ||
      item.className === "access-item-wrapper facility-group"
  }
  )

  if (wrapper) {
    toggleItemCollapsed(parentItem)
    toggleItemCollapsed(target)
    toggleItemCollapsed(wrapper)
  }
}

function updateParentCheckedState(element, selector) {
  // find parent and sibling checkboxes
  const parent = (element.closest(["ul"]).parentNode).querySelector(selector)
  const siblings = nodeListToArray(selector, parent.closest("li").querySelector(["ul"]))

  // get checked state of siblings
  // are every or some siblings checked (using Boolean as test function)
  const checkStatus = siblings.map(check => check.checked)
  const every = checkStatus.every(Boolean)
  const some = checkStatus.some(Boolean)

  // check parent if all siblings are checked
  // set indeterminate if not all and not none are checked
  parent.checked = every
  parent.indeterminate = some && !every

  // recurse until check is the top most parent
  if (element !== parent) updateParentCheckedState(parent, selector)
}

function updateChildrenCheckedState(parent, selector) {
  // check/uncheck children (includes check itself)
  const children = nodeListToArray(selector, parent.closest("li"))

  children.forEach(child => {
    // reset indeterminate state for children
    child.indeterminate = false
    child.checked = parent.checked
  })
}

//
// helpers
//

// helper function to create nodeArrays (not collections)
const nodeListToArray = (selector, parent = document) =>
  [].slice.call(parent.querySelectorAll(selector))

// initialize the access_level select dropdown
function selectAccessLevels() {
  $("#access_level").selectpicker({
    noneSelectedText: "Select an access level..."
  });
}
