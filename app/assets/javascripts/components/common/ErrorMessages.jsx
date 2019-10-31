class ErrorMessages extends React.Component {
    render() {
        if (_.isEmpty(this.props.messages)) {
            return null;
        }

        var messages = _.map(this.props.messages, (message, idx) => {
            return (<li key={idx}>{message}</li>);
        });
        return (
            <div className='error-messages alert alert-danger alert-dismissable fade show'>
                <button type="button" className="close" data-dismiss="alert" aria-label="Close">
                    <i className="fas fa-times"></i>
                </button>
                <ul className='m-0'>{messages}</ul>
            </div>
        );
    }
}