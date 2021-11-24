# frozen_string_literal: true

module PhoneNumberLocalization
  extend ActiveSupport::Concern

  included do
    include PatientPhoneNumberHelper

    def localized_phone_number
      number_with_country_code(phone_number)
    end
  end
end
