class Api::V4::LegacyDataDumpsController < APIController
  def create
    legacy_dump = LegacyMobileDataDump.new(legacy_dump_params)

    if legacy_dump.save
      log_success(legacy_dump)

      render json: {errors: []}, status: :ok
    else
      log_failure(legacy_dump)

      errors = [errors_hash(legacy_dump)]
      render json: {errors: errors}, status: :ok
    end
  end

  private

  def legacy_dump_params
    {
      raw_payload: raw_payload,
      dump_date: Time.current.utc,
      user: current_user,
      mobile_version: mobile_version
    }
  end

  def raw_payload
    {
      "patients" => params.require(:patients)
    }
  end

  def mobile_version
    request.headers["HTTP_X_APP_VERSION"]
  end

  def log_success(legacy_dump)
    Rails.logger.info(
      msg: "legacy_data_dump_created",
      legacy_dump_id: legacy_dump.id,
      user_id: legacy_dump.user_id,
      facility_id: current_facility.id,
      mobile_version: legacy_dump.mobile_version,
      payload_keys: legacy_dump.raw_payload.keys
    )
  end

  def log_failure(legacy_dump)
    Rails.logger.warn(
      msg: "legacy_data_dump_failed",
      user_id: legacy_dump.user_id,
      facility_id: current_facility&.id,
      errors: legacy_dump.errors.full_messages
    )
  end

  def errors_hash(legacy_dump)
    legacy_dump.errors.to_hash.merge(id: legacy_dump.id)
  end
end
