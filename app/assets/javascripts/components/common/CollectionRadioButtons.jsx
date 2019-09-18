class CollectionRadioButtons extends React.Component {
    render() {
        var name = this.props.name;
        var checked_id = this.props.checked_id;
        var updateInput = this.props.updateInput;
        return (<div className="form-group row">
            <label htmlFor="facilities-input" className="col-md-2 col-form-label">Organization<sup>*</sup></label>
            <div className="col-md-10 pt-2">
                {this.props.organizations.map(function (organization, index) {
                    return (
                        <div className="form-check-inline" key={index}>
                            <input className="form-check-input"
                                   name={name}
                                   type="radio"
                                   value={organization[0]}
                                   checked={organization[0] == checked_id}
                                   id={organization[0]}
                                   onChange={(e) => updateInput(name, e.target.value)}/>
                            <label className="form-check-label form-label-light" htmlFor={organization[0]}>
                                {organization[1]}
                            </label>
                        </div>
                    )
                })}
            </div>
        </div>);
    }
}