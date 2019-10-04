class SelectResource extends React.Component {
    render() {
        console.log(this.props.selected_resources);
        var inputDisplay = _.chain(this.props.selected_resources)
            .take(2)
            .map('resource_name')
            .join(', ')
            .value();

        if(_.size(this.props.selected_resources) > 2) {
            inputDisplay += " & " + (_.size(this.props.selected_resources) - 2) + "more";
        }

        return (
            <div>
                <div className="form-group row">
                    <label htmlFor="facilities-input"
                           className="col-md-2 col-form-label">{this.props.resourceType}</label>
                    <div className="col-md-10">
                        <input className="form-control"
                               type="text"
                               value={inputDisplay}
                               readOnly={true}
                               placeholder="Give access to facility groups"
                               id="name-input" required data-toggle="modal" data-target="#exampleModal"/>
                    </div>
                </div>

                <SelectResourceModal {...this.props} />
            </div>
        );
    }
}