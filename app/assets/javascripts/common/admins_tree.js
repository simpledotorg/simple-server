function buildAccessTree() {
    const accessItems = Array.from(document.querySelectorAll(".access-item"))
    const data = _.groupBy(accessItems, (item) => item.dataset.accessType)
    return _out = _.transform(data, (result, value, key) =>
        result[key] = _.transform(value, addAccessItemMetaData, {}))
}

function getAccessItemParentKey(accessType) {
    if (accessType === "facility") return "facilityGroupId"
    if (accessType === "facilityGroup") return "organizationId"
    return "parentId"
}

function addAccessItemMetaData(result, value, _key) {
    const parentKey = getAccessItemParentKey(value.dataset.accessType)
    return result[value.dataset.id] = {
        element: value,
        [parentKey]: value.dataset[parentKey],
        name: value.dataset.name
    }
}