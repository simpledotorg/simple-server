class Api::Current::BloodSugarsController < Api::Current::SyncController

  def sync_from_user
    render json: { errors: [] }, status: :ok
  end

  def sync_to_user
    render json: {
      blood_sugars: [],
      process_token: ""
    }, status: :ok

  end

end