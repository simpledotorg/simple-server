function comparePermissionArrays(array1, array2) {
    return array1.sort().join(',') == array2.sort().join(',');
}

function toggleElement(list, element) {
    var existingElement = _.find(list, element);
    if (_.isUndefined(existingElement)) {
        return _.concat(list, element)
    }

    return _.without(list, existingElement);
}

window.InviteAdminForm = createReactClass({
    displayName: 'InviteAdminForm',

    getInitialState: function () {
        return {
            full_name: null,
            email: null,
            role: null,
            mobile: null,
            location: null,
            organization_id: null,
            selected_permissions: [],
            selected_resources: [],
        }
    },

    render: function () {
        var self = this;

        var updateInput = (key, value) => self.setState({[key]: value});

        var requiredResources = _.chain(self.state.selected_permissions)
            .map('resource_type')
            .uniq()
            .value();

        var updateAccessLevel = (access_level) => {
            var new_permissions = _.chain(self.props.access_levels)
                .find(['name', access_level])
                .get('default_permissions')
                .map((slug) => _.find(self.props.permissions, ['slug', slug]))
                .value();

            self.setState({selected_permissions: new_permissions});
        };

        var updatePermissions = function (permission) {
            var newPermissions = toggleElement(self.state.selected_permissions, permission);
            self.setState({selected_permissions: newPermissions});
        };

        var updateResources = (resources) => {
            self.setState({
                selected_resources: _.chain(this.state.selected_resources)
                    .concat(resources)
                    .uniq()
                    .value()
            });
        };

        var access_level = _.chain(self.props.access_levels)
            .find((al) => comparePermissionArrays(_.map(self.state.selected_permissions, 'slug'), al.default_permissions))
            .get('name', 'custom')
            .value();

        var submitForm = () => {
            var permissions_payload = _.chain(self.state.selected_permissions)
                .flatMap((permission) => _.chain(self.state.selected_resources)
                    .filter({resource_type: permission.resource_type})
                    .map((resource) => {
                        return {permission_slug: permission.slug, ...resource}
                    })
                    .value())
                .value();

            var request_payload = {
                ...this.state,
                permissions_payload: permissions_payload
            };

            $.ajax({
                type: "POST",
                url: "/email_authentications/invitation",
                headers: {
                    'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
                },
                data: request_payload,
                success: () => {
                    window.location.replace("/admins");
                }
            });
        };

        return (
            <div>
                <TextInputField name="full_name" title="Full Name" updateInput={updateInput}/>
                <TextInputField name="email" title="Email" updateInput={updateInput}/>
                <TextInputField name="role" title="Role" updateInput={updateInput}/>
                <TextInputField name="mobile" title="Mobile" updateInput={updateInput}/>
                <TextInputField name="location" title="Location" updateInput={updateInput}/>
                <CollectionRadioButtons name="organization_id" title="Organization"
                                        organizations={this.props.organizations}
                                        checked_id={this.state.organization_id}
                                        updateInput={updateInput}/>
                <AccessLevelComponent permissions={this.props.permissions}
                                      access_levels={this.props.access_levels}
                                      selected_level={access_level}
                                      selected_permissions={this.state.selected_permissions}
                                      selected_resources={this.state.selected_resources}
                                      required_resources={requiredResources}
                                      updateAccessLevel={updateAccessLevel}
                                      updatePermissions={updatePermissions}
                                      updateResources={updateResources}
                                      facility_groups={this.props.facility_groups}
                                      facilities={this.props.facilities}/>
                <button className="btn btn-primary" onClick={submitForm}>Invite Admin</button>
            </div>
        );
    }
})
;