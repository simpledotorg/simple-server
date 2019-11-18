class Api::Current::DiabetesObservationsController < Api::Current::SyncController

  def sync_from_user
    render json: { errors: [] }, status: :ok
  end

  def sync_to_user
    render json: {
      diabetes_observations: [],
      process_token: ""
    }, status: :ok

  end

end