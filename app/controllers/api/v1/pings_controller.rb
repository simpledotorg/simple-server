class Api::V1::PingsController < APIController
  def show
    render json: { status: 'ok' }, status: :ok
  end
end
