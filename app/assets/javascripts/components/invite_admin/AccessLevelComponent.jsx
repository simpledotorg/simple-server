class AccessLevelComponent extends React.Component {

    render() {
        var selectResources = null;

        if(this.props.selected_level != 'owner') {
            selectResources =
                <div>
                    <CollectionRadioButtons name="organization_id" title="Organization"
                                            organizations={this.props.organizations}
                                            checked_id={this.props.checked_id}
                                            updateOrganization={this.props.updateOrganization}/>

                    <SelectResource resourceType='FacilityGroup'
                                    displayName='Facility groups'
                                    resources={this.props.facility_groups}
                                    updateResources={this.props.updateResources}
                                    organization_id={this.props.organization_id}
                                    selected_resources={this.props.selected_resources}/>
                </div>
        }

        return (
            <div>

                <div className="form-group row">
                    <label htmlFor="access-input" className="col-md-2 col-form-label">Access level</label>
                    <div className="col-md-10">
                        <SelectField name="accessLevel"
                                     selected_level={this.props.selected_level}
                                     updateAccessLevel={this.props.updateAccessLevel}
                                     access_levels={this.props.access_levels}/>
                        <CollectionCheckBoxes permissions={this.props.permissions}
                                              selected_permissions={this.props.selected_permissions}
                                              updatePermissions={this.props.updatePermissions}/>
                    </div>
                </div>

                {selectResources}

            </div>
        )
    }
}