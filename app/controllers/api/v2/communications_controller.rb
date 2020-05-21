class Api::V2::CommunicationsController < Api::V3::SyncController
  include Api::V2::LogApiUsageByUsers

  def sync_from_user
    render json: {errors: nil}, status: :ok
  end

  def sync_to_user
    render(
      json: {
        "communications" => [],
        "process_token" => encode_process_token({})
      },
      status: :ok
    )
  end
end
