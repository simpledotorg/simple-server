class CollectionRadioButtons extends React.Component {
    render() {
        var name = this.props.name;
        var checked_id = this.props.checked_id;
        var updateOrganization = this.props.updateOrganization;
        return (<div className="form-group row">
            <label htmlFor="facilities-input" className="col-md-2 col-form-label">Organization<sup>*</sup></label>
            <div className="col-md-10 pt-2">
                {this.props.organizations.map(function (organization, index) {
                    return (
                        <div className="form-check-inline" key={index}>
                            <input className="form-check-input"
                                   name={name}
                                   type="radio"
                                   value={organization.id}
                                   checked={organization.id == checked_id}
                                   id={organization.id}
                                   onChange={(e) => updateOrganization(e.target.value)}/>
                            <label className="form-check-label form-label-light" htmlFor={organization.id}>
                                {organization.name}
                            </label>
                        </div>
                    )
                })}
            </div>
        </div>);
    }
}