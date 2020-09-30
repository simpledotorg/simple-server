const AccessTree = function () {

    const self = this

    getParentKey = function (accessType) {
        if (accessType === "facility") return "facilityGroup"
        if (accessType === "facilityGroup") return "organization"
    }

    getChildKey = function (accessType) {
        if (accessType === "organization") return "facilityGroup"
        if (accessType === "facilityGroup") return "facility"
    }

    getParentIdKey = function (accessType) {
        if (accessType === "facility") return "facilityGroupId"
        if (accessType === "facilityGroup") return "organizationId"
        return "parentId"
    }

    addAccessItemMetaData = function (result, value, _key) {
        const accessType = value.dataset.accessType
        const parentKey = getParentIdKey(accessType)
        const parentId = value.dataset[parentKey]
        return result[value.dataset.id] = {
            element: value,
            [parentKey]: parentId,
            name: value.dataset.name,
            accessType,
            parent: getElementParent(accessType, parentId),
            children: getElementChildren(accessType, value.dataset.id)
        }
    }

    getElementParent = function (accessType, parentId) {
        return function () {
            const tree = self.accessTree
            const parentkey = getParentKey(accessType)
            if (!parentkey) return
            return tree[parentkey][parentId]
        }
    }

    getElementChildren = function (accessType, itemId) {
        return function () {
            const tree = self.accessTree
            const childKey = getChildKey(accessType)
            const parentIdKey = getParentIdKey(childKey)
            if (!childKey) return
            return Object.values(tree[childKey])
                .filter(item => item[parentIdKey] === itemId)
        }
    }

    buildAccessTree = function () {
        const accessItems = Array.from(document.querySelectorAll(".access-item"))
        const data = _.groupBy(accessItems, (item) => item.dataset.accessType)
        return _out = _.transform(data, (result, value, key) =>
            result[key] = _.transform(value, addAccessItemMetaData, {}))
    }

    this.accessTree = buildAccessTree()
}