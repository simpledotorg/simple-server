class MergeTeleconsultationService
  def self.merge(*args)
    new(*args).merge
  end

  def initialize(payload, request_user)
    @payload = payload
    @request_user = request_user
  end

  def merge
    teleconsultation = @payload
      .yield_self { |payload| set_requested_medical_officer(payload) }
      .yield_self { |payload| set_medical_officer(payload) }
    Teleconsultation.merge(teleconsultation)
  end

  def set_requested_medical_officer(payload)
    payload[:requested_medical_officer_id] = payload[:medical_officer_id] if is_request?
    payload
  end

  def set_medical_officer(payload)
    payload.except!(:medical_officer_id) if is_request? && Teleconsultation.find_by(id: payload[:id])
    payload[:medical_officer_id] = @request_user.id if is_record?
    payload
  end

  def is_request?
    @payload[:requested_at].present?
  end

  def is_record?
    @payload[:recorded_at].present?
  end
end
