
window.InviteAdminFormV2 = createReactClass({
  displayName: 'InviteAdminFormV2',

  getInitialState: function () {
    return {
      access_levels: this.props.access_levels,
      accessible_organizations: this.props.accessible_organizations,
      checked: [],
      expanded: [],
    }
  },

  nodes: [{
    value: 'mars',
    label: 'Mars',
    children: [
      { value: 'phobos', label: 'Phobos' },
      { value: 'deimos', label: 'Deimos' },
    ],
  }],

  accessibleOrganizationOptions: function () {
    return this.state.accessible_organizations.map((name, index) =>
      <option key={index} value={name}>{name}</option>)
  },

  accessLevelOptions: function () {
    return this.state.access_levels.map(
      (al, index) => <option key={index} value={al.name}>{al.description}</option>
    );
  },

  render: function () {
    return (
      <div>
        <TextInputField name="full_name" title="Full Name" value={this.state.full_name} />
        <TextInputField readOnly={!this.props.allow_email_edit} name="email" title="Email" value={this.state.email} />
        <TextInputField name="job_title" title="Job Title" value={this.state.role} />

        <div className="form-group row">
          <label htmlFor="name-input" className="col-md-2 col-form-label">Access</label>
          <div className="col-md-10">
            <select className="form-control"
              id="access-input" value={this.props.selected_level}>

              <option>Choose access level...</option>
              {this.accessLevelOptions()}
            </select>
          </div>
        </div>

        <div className="form-group row">
          <label htmlFor="name-input" className="col-md-2 col-form-label">Organization</label>
          <div className="col-md-10">
            <select className="form-control"
              id="access-input" value={this.props.selected_level}>

              <option>Organizations</option>
              {this.accessibleOrganizationOptions()}
            </select>
          </div>
        </div>

        <CheckboxTree
          nodes={[{
            value: 'mars',
            label: 'Mars',
            children: [
              { value: 'phobos', label: 'Phobos' },
              { value: 'deimos', label: 'Deimos' },
            ],
          }]}
          checked={this.state.checked}
          expanded={this.state.expanded}
        />

        <button className="btn btn-primary" onClick={this.submitForm}>
          Send Invite
        </button>

      </div>
    );
  }
})
