var SelectResourceModal = createReactClass({
    displayName: 'SelectResourceModal',

    getInitialState: function () {
        return {
            searchText: "",
            matchingResources: this.props.resources,
            selectedResources: _.get(this.props, 'selected_resources', [])
        };
    },

    render: function () {
        var self = this;

        var updateSearchInput = function (input) {
            var updateHash = {};
            updateHash['searchText'] = input;
            updateHash['matchingResources'] = self.props.resources
                .filter((resource) => resource.name.toLowerCase().includes(input.toLowerCase()));

            self.setState(updateHash);
        };

        var toggleResource = (resourceId, resourceName) => {
            var newResources = toggleElement(self.state.selectedResources, {
                resource_type: self.props.resourceType,
                resource_id: resourceId,
                resource_name: resourceName
            });
            self.setState({selectedResources: newResources})
        };

        var selectAllResources = () => {
            var newResources = _.map(self.state.matchingResources, (resource) => {
                return {
                    resource_type: self.props.resourceType,
                    resource_id: resource.id,
                    resource_name: resource.name
                };
            });
            self.setState({selectedResources: newResources});
        };

        var selectedResources = self.state.selectedResources;
        var displayResources = _.filter(this.state.matchingResources, (resource) => {
            return resource.organization_id == this.props.organization_id;
        });
        var resources = displayResources.map((resource, index) =>
            <div className="form-check" key={index}>
                <input className="form-check-input"
                       type="checkbox"
                       value={resource.id}
                       checked={!_.isUndefined(_.find(selectedResources, ['resource_id', resource.id]))}
                       onChange={() => toggleResource(resource.id, resource.name)}
                       id={resource.id}/>
                <label className="form-check-label form-label-light" htmlFor={resource.id}>
                    {resource.name}
                </label>
            </div>
        );

        return (
            <div className="modal fade" id="exampleModal" tabIndex="-1" role="dialog"
                 aria-labelledby="exampleModalLabel" aria-hidden="true">
                <div className="modal-dialog modal-dialog-scrollable" role="document">
                    <div className="modal-content">
                        <div className="modal-header">
                            <h3 className="modal-title" id="exampleModalLabel">Select facilities or districts</h3>
                            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div className="modal-body">
                            <div className="input-group mb-3">
                                <input type="text"
                                       className="form-control"
                                       placeholder="Search by district or facility name..."
                                       value={this.state.searchText}
                                       onChange={(e) => updateSearchInput(e.target.value)}
                                />
                            </div>
                            <div className="p-3">
                                {resources}
                            </div>
                        </div>
                        <div className="modal-footer justify-content-between">
                            <button type="button" className="btn btn-outline-success" onClick={selectAllResources}>
                                Give access to all facilities
                            </button>
                            <button type="button" className="btn btn-primary" data-dismiss="modal" aria-label="Done"
                                    onClick={() => this.props.updateResources(this.state.selectedResources)}>
                                Done
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
});