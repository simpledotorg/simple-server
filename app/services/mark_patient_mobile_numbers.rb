# frozen_string_literal: true

class MarkPatientMobileNumbers
  prepend SentryHandler

  def self.call
    new.call
  end

  def call
    return unless Flipper.enabled?(:force_mark_patient_mobile_numbers)

    count = non_mobile_numbers.count + nil_type_numbers.count
    notify("Force-marking #{count} as mobile numbers")

    non_mobile_numbers.update_all(phone_type: "mobile")
    nil_type_numbers.update_all(phone_type: "mobile")

    notify("Finished force-marking #{count} as mobile numbers")
  end

  private

  def non_mobile_numbers
    PatientPhoneNumber.where.not(phone_type: "mobile")
  end

  def nil_type_numbers
    PatientPhoneNumber.where(phone_type: nil)
  end

  def notify(msg)
    Rails.logger.info msg: msg, class: self.class.name
  end
end
