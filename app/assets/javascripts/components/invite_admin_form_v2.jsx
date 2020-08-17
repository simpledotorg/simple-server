window.InviteAdminFormV2 = createReactClass({
  displayName: 'InviteAdminFormV2',

  getInitialState: function () {
    return {
      access_levels: this.props.access_levels
    }
  },

  accessLevelOptions: function() {
    return this.state.access_levels.map(
      (al, index) => <option key={index} value={al.name}>{al.description}</option>
    );
  },

  render: function () {
    return (
      <div>
        <TextInputField name="full_name" title="Full Name" value={this.state.full_name}/>
        <TextInputField readOnly={!this.props.allow_email_edit} name="email" title="Email" value={this.state.email} />
        <TextInputField name="job_title" title="Job Title" value={this.state.role} />

        <select className="form-control" id="access-input" value={this.props.selected_level}>
          <option>Choose access level...</option>
          {this.accessLevelOptions()}
        </select>
      </div>
    );
  }
})
