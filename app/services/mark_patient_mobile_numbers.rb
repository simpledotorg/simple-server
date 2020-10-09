class MarkPatientMobileNumbers
  def self.call
    new.call
  end

  def call
    return unless Flipper.enabled?(:force_mark_patient_mobile_numbers)

    count = eligible_numbers.count
    notify("Force-marking #{count} as mobile numbers")

    eligible_numbers.update_all(phone_type: "mobile")

    notify("Finished force-marking #{count} as mobile numbers")
  end

  private

  def eligible_numbers
    PatientPhoneNumber.where.not(phone_type: "mobile")
  end

  def notify(msg)
    Rails.logger.info msg: msg, class: self.class.name
  end
end
