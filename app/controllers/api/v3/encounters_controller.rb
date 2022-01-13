class Api::V3::EncountersController < Api::V3::SyncController
  before_action :stub_syncing_from_user, only: [:sync_from_user]
  before_action :stub_syncing_to_user, only: [:sync_to_user]

  def sync_from_user
    __sync_from_user__(encounter_params)
  end

  def sync_to_user
    __sync_to_user__("encounters")
  end

  def generate_id
    raise ActionController::RoutingError.new("Not Found") unless Flipper.enabled?("generate_encounter_id_endpoint")

    params.require([:facility_id, :patient_id, :encountered_on])

    render plain: Encounter.generate_id(params[:facility_id].strip,
      params[:patient_id].strip,
      params[:encountered_on].strip),
      status: :ok
  end

  private

  def encounter_facility_id(encounter_params)
    return current_facility.id if encounter_params["observations"].values.flatten.empty?

    encounter_params["observations"].values.flatten.first[:facility_id]
  end

  def merge_if_valid(encounter_params)
    validator = Api::V3::EncounterPayloadValidator.new(encounter_params)
    logger.debug "Encounter had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V3::EncounterTransformer
        .from_nested_request(encounter_params)
        .merge(facility_id: encounter_facility_id(encounter_params))
      {record: MergeEncounterService.new(transformed_params,
        current_user,
        current_timezone_offset).merge[:encounter]}
    end
  end

  def transform_to_response(encounter)
    Api::V3::EncounterTransformer.to_response(encounter)
  end

  def encounter_params
    permitted_bp_params =
      %i[id systolic diastolic patient_id facility_id user_id created_at updated_at recorded_at deleted_at]

    params.require(:encounters).map do |encounter_params|
      encounter_params.permit(
        :id,
        :patient_id,
        :created_at,
        :updated_at,
        :deleted_at,
        :notes,
        :encountered_on,
        observations: [blood_pressures: [permitted_bp_params]]
      )
    end
  end

  def stub_syncing_from_user
    render(json: {errors: nil}, status: :ok) unless Flipper.enabled?("sync_encounters")
  end

  def stub_syncing_to_user
    unless Flipper.enabled?("sync_encounters")
      render(
        json: {"encounters" => [], "process_token" => encode_process_token({})},
        status: :ok
      )
    end
  end
end
