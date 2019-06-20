class AnonymizedDataDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 3
  DEFAULT_RETRY_SECONDS = 5.minutes.seconds.to_i

  def perform(recipient_name, recipient_email, model_params_map, model_type)
    case model_type
    when 'district' then
      AnonymizedDataDownloadService.new.run_for_district(recipient_name,
                                                         recipient_email,
                                                         model_params_map[:district_name],
                                                         model_params_map[:organization_id]).execute
    when 'facility' then
      AnonymizedDataDownloadService.new.run_for_facility(recipient_name,
                                                         recipient_email,
                                                         model_params_map[:facility_id]).execute
    else
      raise StandardError("Unknown model type #{model_type}")
    end
  end
end
