class Api::V1::CommunicationsController < Api::V2::CommunicationsController
  include Api::V1::ApiControllerOverrides

  def sync_to_user
    render(
      json: {
        'communications' => [],
        'processed_since' => Time.new(0)
      },
      status: :ok
    )
  end
end
