class SelectResource extends React.Component {
    render() {
        return (
            <div>
                <div className="form-group row">
                    <label htmlFor="facilities-input"
                           className="col-md-2 col-form-label">{this.props.resourceType}</label>
                    <div className="col-md-10">
                        <input className="form-control"
                               type="text"
                               placeholder="Give access to facility groups"
                               id="name-input" required data-toggle="modal" data-target="#exampleModal"/>
                    </div>
                </div>

                <SelectResourceModal {...this.props} />
            </div>
        );
    }
}