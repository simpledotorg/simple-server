class Api::Current::PingsController < APIController
  skip_before_action :authenticate, only: [:show]
  skip_before_action :validate_facility, only: [:show]

  def show
    render json: { status: 'ok' }, status: :ok
  end
end
