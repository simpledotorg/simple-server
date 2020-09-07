//
// elements
//
const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const $facilityAccessDiv = () => document.getElementById("facility-access")
const $selectAllFacilitiesContainer = () => document.getElementById("select-all-facilities")
const $selectAllFacilitiesInput = () => document.getElementById("select-all-facilities-input")
const $facilityAccessItemsAccessRatio = () => document.getElementsByClassName("access-ratio")
const $facilityAccessItemsPadding = () => document.getElementsByClassName("access-item__padding")
const $facilityAccessPowerUser = () => document.getElementById("facility-access-power-user")
const $accessLevel = () => document.getElementById("access_level")
const $page = () => document.getElementById("facility-access").attributes.getNamedItem('data-page').value

//
// load things upfront
//
window.addEventListener("DOMContentLoaded", onPageLoad);

function onPageLoad() {
  accessLevelListener()
  accessLevelSelector()
}

//
// wait for the render_async hook before loading the access tree related JS
//
document.addEventListener('render_async_load', function (_event) {
  selectAllButtonListener()
  checkboxItemListener()
  resourceRowCollapseListener()
  editAdmin()
});

function editAdmin() {
  if ($page() !== "edit") return

  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, $facilityAccessDiv())

  // go through all the checkboxes that are pre-checked and update their parents accordingly
  for (const checkbox of checkboxes) {
    if (!checkbox.checked) continue

    // a large tree can take a lot of time to load on the DOM,
    // so we queue up our updates by requesting frames so as to not cause overwhelming repaints
    requestAnimationFrame(function () {
      updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
    })
  }

  $selectAllFacilitiesInput().checked = checkboxes.every(checkbox => checkbox.checked)
}

//
// selecting the access level
//
function accessLevelSelector() {
  // initialize the access_level select dropdown
  $("#access_level").selectpicker({
    noneSelectedText: "Select an access level..."
  });
}

function accessLevelListener() {
  $accessLevel().addEventListener("change", onAccessLevelChanged)
}

function toggleAccessTreeVisibility(isPowerUser) {
  if (isPowerUser) {
    $facilityAccessDiv().classList.add("hidden")
    $facilityAccessPowerUser().classList.remove("hidden")
  } else {
    $facilityAccessDiv().classList.remove("hidden")
    $facilityAccessPowerUser().classList.add("hidden")
  }
}

function onAccessLevelChanged({target}) {
  toggleAccessTreeVisibility(target.value === "power_user")
}

//
// manipulating the access tree
//
function checkboxItemListener() {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, $facilityAccessDiv())

  addEventListener("change", e => {
    const targetCheckbox = e.target

    // exit if change event did not come from list of checkboxes
    if (checkboxes.indexOf(targetCheckbox) === -1) return

    updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
    updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
  })
}

function resourceRowCollapseListener() {
  const collapsibleItems = [
    $facilityAccessItemsPadding(),
    $facilityAccessItemsAccessRatio()
  ].map(htmlCollection => Array.from(htmlCollection)).flat()

  for (const item of collapsibleItems) {
    item.addEventListener("click", onFacilityAccessItemToggled)
  }
}

function toggleItemCollapsed(element) {
  const collapsed = element.classList.contains("collapsed")

  if (collapsed) {
    element.classList.remove("collapsed")
  } else {
    element.classList.add("collapsed")
  }
}

function onFacilityAccessItemToggled({target}) {
  const children = Array.from(target.closest("li").childNodes)
  const parentItem = target.closest(".access-item")
  const wrapper = children.find(containsClass("access-item-wrapper"))

  if (wrapper) {
    toggleItemCollapsed(parentItem)
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
// select all button for facility access
//
function selectAllButtonListener() {
  if (!$selectAllFacilitiesInput()) return
  $selectAllFacilitiesContainer().hidden = false;

  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, $facilityAccessDiv())

  $selectAllFacilitiesInput().addEventListener("change", () => {
    for (const checkbox of checkboxes) {
      checkbox.checked = $selectAllFacilitiesInput().checked
    }
  })
}

//
// helpers
//
const nodeListToArray = (selector, parent = document) =>
  // create nodeArrays (not collections)
  [].slice.call(parent.querySelectorAll(selector))

// return a function that checks if element contains class
const containsClass = (className) => ({classList}) =>
  classList && classList.contains(className)

