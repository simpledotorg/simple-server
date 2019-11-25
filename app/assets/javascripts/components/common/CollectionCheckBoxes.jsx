class CollectionCheckBoxes extends React.Component {
    render() {
        var selected_permissions = this.props.selected_permissions;

        var updatePermissions = this.props.updatePermissions;
        var permissions = this.props.permissions.map(function (permission, index) {
            return (<div className="form-check" key={index}>
                <input className="form-check-input"
                       type="checkbox"
                       value={permission.slug}
                       checked={_.find(selected_permissions, permission) != undefined}
                       onChange={() => updatePermissions(permission)}
                       id={permission.slug}/>
                <label className="form-check-label form-label-light" htmlFor={permission.slug}>
                    {permission.description}
                </label>
            </div>);
        });
        return (
            <div className="mt-3 p-3">
                <div className="row">
                    <div className="col-md-6">
                        {permissions}
                    </div>
                </div>
            </div>
        )
    }
}