var SelectResourceModal = createReactClass({
    displayName: 'SelectResourceModal',

    getInitialState: function () {
        return {
            searchText: "",
            matchingResources: this.props.resources,
            selectedResources: _.get(this.props, 'selected_resources', [])
        };
    },

    updateSearchInput: function (input) {
        var updateHash = {};
        updateHash['searchText'] = input;
        updateHash['matchingResources'] = this.props.resources
            .filter((resource) => resource.name.toLowerCase().includes(input.toLowerCase()));

        this.setState(updateHash);
    },

    toggleResource: function (resourceId, resourceName) {
        var newResources = toggleElement(this.state.selectedResources, {
            resource_type: this.props.resourceType,
            resource_id: resourceId,
            resource_name: resourceName
        });
        this.setState({selectedResources: newResources})
    },

    displayResources: function() {
        return _.filter(this.state.matchingResources, (resource) => {
            return resource.organization_id == this.props.organization_id;
        });
    },

    selectAllResources: function () {
        var newResources = _.map(this.displayResources(), (resource) => {
            return {
                resource_type: this.props.resourceType,
                resource_id: resource.id,
                resource_name: resource.name
            };
        });
        this.setState({selectedResources: newResources});
    },

    renderResources: function() {
        return this.displayResources().map((resource, index) =>
            <div className="form-check" key={index}>
                <input className="form-check-input"
                       type="checkbox"
                       value={resource.id}
                       checked={!_.isUndefined(_.find(this.state.selectedResources, ['resource_id', resource.id]))}
                       onChange={() => this.toggleResource(resource.id, resource.name)}
                       id={resource.id}/>
                <label className="form-check-label form-label-light" htmlFor={resource.id}>
                    {resource.name}
                </label>
            </div>
        );
    },

    render: function () {
        return (
            <div className="modal fade" id="exampleModal" tabIndex="-1" role="dialog"
                 aria-labelledby="exampleModalLabel" aria-hidden="true">
                <div className="modal-dialog modal-dialog-scrollable" role="document">
                    <div className="modal-content">
                        <div className="modal-header">
                            <h3 className="modal-title" id="exampleModalLabel">Select {this.props.displayName}</h3>
                            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div className="modal-body">
                            <div className="input-group mb-3">
                                <input type="text"
                                       className="form-control"
                                       placeholder={"Search " + this.props.displayName}
                                       value={this.state.searchText}
                                       onChange={(e) => this.updateSearchInput(e.target.value)}
                                />
                            </div>
                            <div className="p-3">
                                {this.renderResources()}
                            </div>
                        </div>
                        <div className="modal-footer justify-content-between">
                            <button type="button" className="btn btn-outline-success" onClick={this.selectAllResources}>
                                Give access to all {this.props.displayName}
                            </button>
                            <button type="button" className="btn btn-primary" data-dismiss="modal" aria-label="Done"
                                    onClick={() => this.props.updateResources(this.state.selectedResources)}>
                                Done
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
});