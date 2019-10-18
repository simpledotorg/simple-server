class ErrorMessage extends React.Component {
    render() {
        return (<div className="alert alert-danger alert-dismissable fade show">
            {this.props.message}
            <button type="button" className="close" data-dismiss="alert" aria-label="Close">
                <i className="fas fa-times"></i>
            </button>
        </div>)
    }
}