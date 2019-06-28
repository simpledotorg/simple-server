class AnonymizedDataDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 3
  DEFAULT_RETRY_SECONDS = 5.minutes.seconds.to_i

  def perform(recipient_name, recipient_email, model_params_map, model_type)
    case model_type
    when 'district' then
      begin
        AnonymizedData::DownloadService.new.run_for_district(recipient_name,
                                                             recipient_email,
                                                             model_params_map[:district_name],
                                                             model_params_map[:organization_id])
      rescue StandardError => e
        error_message = "Error while downloading anonymized data for District #{model_params_map[:district_name]}"
        report_error(e.message, error_message)
      end
    when 'facility' then
      begin
        AnonymizedData::DownloadService.new.run_for_facility(recipient_name,
                                                             recipient_email,
                                                             model_params_map[:facility_id])
      rescue StandardError => e
        facility name = Facility.where(id: model_params_map[:facility_id]).first
        error_message = "Error while downloading anonymized data for District #{facility_name}"
        report_error(e.message, error_message)
      end
    else
      raise StandardError("Error while downloading anonymized data: unknown model type #{model_type}")
    end
  end

  private

  def report_error(error_message, error_string)
    Raven.capture_message(error_string,
                          logger: 'logger',
                          extra: {
                            errors: error_message
                          },
                          tags: { type: 'anonymized-data-download' })

  end
end
