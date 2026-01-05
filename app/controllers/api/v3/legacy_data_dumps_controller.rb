class Api::V3::LegacyDataDumpsController < APIController
  def create
    legacy_dump = LegacyMobileDataDump.new(legacy_dump_params)

    if legacy_dump.save
      log_success(legacy_dump)

      render json: { id: legacy_dump.id, status: "ok" }, status: :ok
    else
      log_failure(legacy_dump)

      render json: { errors: legacy_dump.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def legacy_dump_params
    {
      raw_payload: raw_payload,
      dump_date: Time.current,
      user_id: user_id,
      mobile_version: mobile_version
    }
  end

  def raw_payload
    params.require(:legacy_data_dump).to_unsafe_h
  end

  def user_id
    params.dig(:legacy_data_dump, :user) ||
      request.headers["X-USER-ID"]
  end

  def mobile_version
    params.dig(:legacy_data_dump, :mobile_version) ||
      request.headers["X-APP-VERSION"]
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
end
