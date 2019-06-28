class AnonymizedDataDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(recipient_name, recipient_email, model_params_map, model_type)
    case model_type
    when 'district' then
      AnonymizedData::DownloadService.new.run_for_district(recipient_name,
                                                           recipient_email,
                                                           model_params_map[:district_name],
                                                           model_params_map[:organization_id])
    when 'facility' then
      AnonymizedData::DownloadService.new.run_for_facility(recipient_name,
                                                           recipient_email,
                                                           model_params_map[:facility_id])
    end
  end
end


