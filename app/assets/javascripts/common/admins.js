//
// elements
//
const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const ACCESS_LEVEL_ID = "access-level"
const ACCESS_LEVEL_POWER_USER = "power_user"
const ACCESS_LIST_CLICK_ELEMENT = "access-item__dropdown"

AdminAccess = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccess.prototype = {
  accessLevel: () => document.getElementById(ACCESS_LEVEL_ID),

  facilityAccessPowerUser: () => document.getElementById("facility-access-power-user"),

  selectAllFacilitiesContainer: function () {
    return document.getElementById("select-all-facilities")
  },

  totalSelectedFacilitiesDiv: function () {
    return document.getElementById("total-selected-facilities")
  },

  checkboxItemListener: function () {
    // list of all checkboxes under facilityAccess()
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)

    addEventListener("change", e => {
      const targetCheckbox = e.target

      // exit if change event did not come from list of checkboxes
      if (checkboxes.indexOf(targetCheckbox) === -1) return

      this.updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
      this.updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
      this.updateTotalFacilityCount()
    })
  },

  resourceRowCollapseListener: function () {
    const collapsibleItems = [
      document.getElementsByClassName(ACCESS_LIST_CLICK_ELEMENT)
    ].map(htmlCollection => Array.from(htmlCollection)).flat()

    for (const item of collapsibleItems) {
      item.addEventListener("click", this.onFacilityAccessItemToggled.bind(this))
    }
  },

  toggleAccessTreeVisibility: function (isPowerUser) {
    if (isPowerUser) {
      this.facilityAccess.classList.add("hidden")
      this.facilityAccessPowerUser().classList.remove("hidden")
    } else {
      this.facilityAccess.classList.remove("hidden")
      this.facilityAccessPowerUser().classList.add("hidden")
    }
  },

  onAccessLevelChanged: function ({target}) {
    this.toggleAccessTreeVisibility(target.value === ACCESS_LEVEL_POWER_USER)
  },

  toggleItemCollapsed: function (element) {
    const collapsed = element.classList.contains("collapsed")

    if (collapsed) {
      element.classList.remove("collapsed")
    } else {
      element.classList.add("collapsed")
    }
  },

  onFacilityAccessItemToggled: function ({target}) {
    const children = Array.from(target.closest("li").childNodes)
    const parentItem = target.closest(".access-item")
    const wrapper = children.find(containsClass("access-item-wrapper"))

    if (wrapper) {
      this.toggleItemCollapsed(parentItem)
    }
  },

  updateParentCheckedState: function (element, selector) {
    // find parent and sibling checkboxes
    const parent = (element.closest(["ul"]).parentNode).querySelector(selector)

    if (parent === element) {
      this.updateSelectAllCheckbox()
      return
    }

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
    if (element !== parent) {
      this.updateParentCheckedState(parent, selector)
    }
  },

  updateTotalFacilityCount: function () {
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    const selected = this.getSelectedCount(checkboxes)[0]

    this.totalSelectedFacilitiesDiv().textContent = `${selected} facilities selected`
  },

  findAndUpdateFacilityCount: function () {
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    const orgCheckboxes = checkboxes.filter(({name}) => name === "organizations[]")

    orgCheckboxes.forEach(this.updateFacilityCount.bind(this))
  },

  // walk down the tree and get the first node for each FG, then walk up the tree
  // and update the counts
  updateFacilityCount: function (element) {
    const self = this
    const leafNodesByFacilityGroup = this.getLeafNodesByFacilityGroup(element)
    const facilities = Object.values(leafNodesByFacilityGroup).filter(node => node.length > 0)

    facilities.forEach(([node]) => self.updateParentFacilityCount(node, ACCESS_LIST_INPUT_SELECTOR))
    this.updateTotalFacilityCount()
  },

  getSelectedCount: function (childNodes) {
    return childNodes
      .filter(({name}) => name === "facilities[]")
      .reduce(([selected, notSelected], item) =>
        item.checked ? [selected + 1, notSelected] : [selected, notSelected + 1], [0, 0])
  },

  setAccessRatio: function (div, selected, notSelected) {
    div.textContent = notSelected === 0
      ? `${selected} facilities selected`
      : `${selected} of ${selected + notSelected} facilities selected`
  },

  getParentNode: function (element, selector) {
    return element.closest(["ul"]).parentNode.querySelector(selector)
  },

  getChildNodes: function (parent, selector) {
    return nodeListToArray(selector, parent.closest("li").querySelector(["ul"]))
  },

  updateParentFacilityCount: function (element, selector) {
    const parent = this.getParentNode(element, selector)
    const children = this.getChildNodes(parent, selector)
    const selectedCount = this.getSelectedCount(children)
    const selected = selectedCount[0]
    const notSelected = selectedCount[1]
    const accessRatioDiv = element.closest(["ul"]).parentNode.querySelector(".access-ratio")
    this.setAccessRatio(accessRatioDiv, selected, notSelected)

    if (element !== parent) {
      this.updateParentFacilityCount(parent, selector)
    }
  },

  getLeafNodesByFacilityGroup: function (element) {
    const parent = element.closest("li")
    const children = Array.from(parent.querySelectorAll(".access-item"))

    return children
      .filter(item => item.dataset.facilityGroupId)
      .reduce((nodes, item) => {
        const facilityGroupId = item.dataset.facilityGroupId
        const itemsInGroup = nodes[facilityGroupId] ? [...nodes[facilityGroupId], item] : [item]
        return Object.assign(nodes, {[facilityGroupId]: itemsInGroup})
      }, {})
  },

  updateChildrenCheckedState: function (parent, selector) {
    // check/uncheck children (includes check itself)
    const children = nodeListToArray(selector, parent.closest("li"))

    children.forEach(child => {
      // reset indeterminate state for children
      child.indeterminate = false
      child.checked = parent.checked
    })
  },

  onAsyncLoaded: function () {
    const _self = this

    document.addEventListener('render_async_load', function (_event) {
      _self.resourceRowCollapseListener()
    });
  },

  onDOMLoaded: function() {
    document.addEventListener('DOMContentLoaded', (_event) => {
      this.resourceRowCollapseListener()
    });
  },

  initialize: function (async = true) {
    if(async) {
      this.onAsyncLoaded()
    } else {
      this.onDOMLoaded()
    }
  }
}

AdminAccessInvite = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccessInvite.prototype = Object.create(AdminAccess.prototype)
AdminAccessInvite.prototype = Object.assign(AdminAccessInvite.prototype, {
  selectAllFacilitiesInput: () => document.getElementById("select-all-facilities-input"),

  updateSelectAllCheckbox: function () {
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    this.selectAllFacilitiesInput().checked = checkboxes.every(checkbox => checkbox.checked)
  },

  parentID: function(checkbox) {
    return checkbox.dataset.parentId
  },

  updateIndeterminateCheckboxes: function () {
    const _self = this

    // list of all checkboxes under facilityAccess
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    const oneChildPerParent = distinctByFn(checkboxes, this.parentID);

    for (const checkbox of oneChildPerParent) {
      // a large tree can take a lot of time to load on the DOM,
      // so we queue up our updates by requesting frames so as to not cause overwhelming repaints
      requestAnimationFrame(function () {
        _self.updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
      })
    }

    this.updateSelectAllCheckbox()
  },

  selectAllButtonListener: function () {
    this.selectAllFacilitiesContainer().hidden = false

    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)

    const _self = this
    this.selectAllFacilitiesInput().addEventListener("change", () => {
      for (const checkbox of checkboxes) {
        checkbox.indeterminate = false
        checkbox.checked = _self.selectAllFacilitiesInput().checked
      }
      _self.updateTotalFacilityCount()
    })
  },

  accessLevelSelector: function () {
    const accessLevel = $(`#${ACCESS_LEVEL_ID}`)

    // initialize the access_level select dropdown
    return accessLevel.selectpicker({
      noneSelectedText: "Select an access level..."
    });
  },

  accessLevelListener: function () {
    this.accessLevel().addEventListener("change", this.onAccessLevelChanged.bind(this))
  },

  onDOMLoaded: function () {
    const _self = this

    window.addEventListener("DOMContentLoaded", function () {
      _self.accessLevelSelector()
      _self.accessLevelListener()
    })
  },

  onAsyncLoaded: function () {
    const _self = this

    document.addEventListener('render_async_load', function () {
      _self.selectAllButtonListener()
      _self.checkboxItemListener()
      _self.resourceRowCollapseListener()
      _self.updateIndeterminateCheckboxes()
      _self.updateTotalFacilityCount()
    });
  },

  initialize: function () {
    this.onDOMLoaded()
    this.onAsyncLoaded()
  }
})

AdminAccessEdit = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccessEdit.prototype = Object.create(AdminAccessInvite.prototype)
AdminAccessEdit.prototype = Object.assign(AdminAccessEdit.prototype, {
  accessLevelSelector: function () {
    const _super = AdminAccessInvite.prototype.accessLevelSelector.call(this)

    this.toggleAccessTreeVisibility(_super.val() === ACCESS_LEVEL_POWER_USER)
  }
})

//
// helpers
//
const nodeListToArray = (selector, parent = document) =>
  // create nodeArrays (not collections)
  [].slice.call(parent.querySelectorAll(selector))

// return a function that checks if element contains class
const containsClass = (className) => ({classList}) =>
  classList && classList.contains(className)

const distinctByFn = function (collection, fn) {
  return Object.values(
    collection.reduce(function (accumulator, item) {
      accumulator[fn(item)] = item
      return accumulator
    }, {})
)}
