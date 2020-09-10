//
// elements
//
const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const ACCESS_LEVEL_POWER_USER = "power_user"

AdminCommons = function () { }

AdminCommons.prototype.facilityAccess = () => document.getElementById("facility-access")
AdminCommons.prototype.accessLevel = () => document.getElementById("access_level")
AdminCommons.prototype.facilityAccessPowerUser = () => document.getElementById("facility-access-power-user")

AdminCommons.prototype.facilityAccessItemsPadding = function () {
  return document.getElementsByClassName("access-item__padding")
}

AdminCommons.prototype.facilityAccessItemsAccessRatio = function () {
  return document.getElementsByClassName("access-ratio")
}

AdminCommons.prototype.selectAllFacilitiesContainer = function () {
  return document.getElementById("select-all-facilities")
}

//
// manipulating the access tree
//
AdminCommons.prototype.checkboxItemListener = function () {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess())
  addEventListener("change", e => {
    const targetCheckbox = e.target

    // exit if change event did not come from list of checkboxes
    if (checkboxes.indexOf(targetCheckbox) === -1) return

    this.updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
    this.updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
  })
}

AdminCommons.prototype.resourceRowCollapseListener = function () {
  const collapsibleItems = [
    this.facilityAccessItemsPadding(),
    this.facilityAccessItemsAccessRatio()
  ].map(htmlCollection => Array.from(htmlCollection)).flat()

  for (const item of collapsibleItems) {
    item.addEventListener("click", this.onFacilityAccessItemToggled.bind(this))
  }
}

AdminCommons.prototype.toggleAccessTreeVisibility = function (isPowerUser) {
  if (isPowerUser) {
    this.facilityAccess().classList.add("hidden")
    this.facilityAccessPowerUser().classList.remove("hidden")
  } else {
    this.facilityAccess().classList.remove("hidden")
    this.facilityAccessPowerUser().classList.add("hidden")
  }
}

AdminCommons.prototype.onAccessLevelChanged = function ({ target }) {
  this.toggleAccessTreeVisibility(target.value === ACCESS_LEVEL_POWER_USER)
}

AdminCommons.prototype.toggleItemCollapsed = function (element) {
  const collapsed = element.classList.contains("collapsed")

  if (collapsed) {
    element.classList.remove("collapsed")
  } else {
    element.classList.add("collapsed")
  }
}

AdminCommons.prototype.onFacilityAccessItemToggled = function ({ target }) {
  const children = Array.from(target.closest("li").childNodes)
  const parentItem = target.closest(".access-item")
  const wrapper = children.find(containsClass("access-item-wrapper"))

  if (wrapper) {
    this.toggleItemCollapsed(parentItem)
  }
}

AdminCommons.prototype.updateParentCheckedState = function (element, selector) {
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
  if (element !== parent) this.updateParentCheckedState(parent, selector)
}

AdminCommons.prototype.updateChildrenCheckedState = function (parent, selector) {
  // check/uncheck children (includes check itself)
  const children = nodeListToArray(selector, parent.closest("li"))

  children.forEach(child => {
    // reset indeterminate state for children
    child.indeterminate = false
    child.checked = parent.checked
  })
}

AdminCommons.prototype.onAsyncLoaded = function () {
  const _self = this
  document.addEventListener('render_async_load', function (_event) {
    _self.resourceRowCollapseListener()
  });
}
AdminInvite = function () { }

AdminInvite.prototype = Object.create(AdminCommons.prototype)

AdminInvite.prototype.selectAllFacilitiesInput = () => document.getElementById("select-all-facilities-input")

AdminInvite.prototype.updateIndeterminateCheckboxes = function () {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess())

  // go through all the checkboxes that are pre-checked and update their parents accordingly
  for (const checkbox of checkboxes) {
    if (!checkbox.checked) continue

    // a large tree can take a lot of time to load on the DOM,
    // so we queue up our updates by requesting frames so as to not cause overwhelming repaints
    const _self = this
    requestAnimationFrame(function () {
      _self.updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
    })
  }

  this.selectAllFacilitiesInput().checked = checkboxes.every(checkbox => checkbox.checked)
}

AdminInvite.prototype.selectAllButtonListener = function () {
  // if (!this.selectAllFacilitiesInput) return
  this.selectAllFacilitiesContainer().hidden = false

  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess())
  const _self = this
  this.selectAllFacilitiesInput().addEventListener("change", () => {
    for (const checkbox of checkboxes) {
      checkbox.indeterminate = false
      checkbox.checked = _self.selectAllFacilitiesInput().checked
    }
  })
}


// ON DOM LOAD
AdminInvite.prototype.accessLevelSelector = function () {
  const accessLevel = $("#access_level")
  // initialize the access_level select dropdown
  accessLevel.selectpicker({
    noneSelectedText: "Select an access level..."
  });
}

// ON DOM LOAD
AdminInvite.prototype.accessLevelListener = function () {
  this.accessLevel().addEventListener("change", this.onAccessLevelChanged.bind(this))
}

AdminInvite.prototype.onDOMLoaded = function () {
  const _self = this
  window.addEventListener("DOMContentLoaded", function () {
    _self.accessLevelSelector()
    _self.accessLevelListener()
  })
}

AdminInvite.prototype.onAsyncLoaded = function () {
  const _self = this
  document.addEventListener('render_async_load', function () {
    _self.selectAllButtonListener()
    _self.checkboxItemListener()
    _self.resourceRowCollapseListener()
    _self.updateIndeterminateCheckboxes()
  });
}
AdminEdit = function () { }

AdminEdit.prototype = Object.create(AdminInvite.prototype)

AdminEdit.prototype.accessLevelSelector = function () {
  AdminInvite.prototype.accessLevelSelector.call(this)
  const accessLevel = $("#access_level")
  this.toggleAccessTreeVisibility(accessLevel.val() === ACCESS_LEVEL_POWER_USER)
}
//
// helpers
//
const nodeListToArray = (selector, parent = document) =>
  // create nodeArrays (not collections)
  [].slice.call(parent.querySelectorAll(selector))

// return a function that checks if element contains class
const containsClass = (className) => ({ classList }) =>
  classList && classList.contains(className)