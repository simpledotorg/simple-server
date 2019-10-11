class SelectField extends React.Component {
    render() {
        var accessLevels = this.props.access_levels.map(
            (al, index) => <option key={index} value={al.name}>{al.description}</option>
        );
        var updateAccessLevel = this.props.updateAccessLevel;
        return (
            <select className="form-control" id="access-input"
                    value={this.props.selected_level}
                    onChange={(e) => updateAccessLevel(e.target.value)}>
                <option>Choose access level...</option>
                {accessLevels}
            </select>
        );
    }
}