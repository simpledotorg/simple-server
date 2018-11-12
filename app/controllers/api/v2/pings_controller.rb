class Api::V2::PingsController < APIController
  skip_before_action :authenticate, only: [:show]

  def show
    render json: { status: 'ok' }, status: :ok
  end
end
