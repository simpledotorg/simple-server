# frozen_string_literal: true

# Override Faker::PhoneNumber to generate only numeric phone numbers
#
# Problem:
# Faker::PhoneNumber.phone_number can generate phone numbers with alphabetic
# characters (e.g., "1-800-FLOWERS", "555-CALL-NOW") which fail application
# validations that expect numeric-only phone numbers (/\A[0-9]+\z/).
#
# Solution:
# Monkey-patch Faker to always return 10-digit numeric strings without any
# special characters or letters.
#
# This centralized fix applies to all factories that use Faker::PhoneNumber,
# eliminating the need to change each factory individually.

Faker::PhoneNumber.class_eval do
  class << self
    # Override to generate numeric-only 10-digit phone numbers
    # @return [String] A 10-digit numeric string (e.g., "5847293016")
    def phone_number
      rand(1_000_000_000...10_000_000_000).to_s
    end

    # Override cell_phone to match phone_number behavior
    # @return [String] A 10-digit numeric string (e.g., "7382940156")
    def cell_phone
      rand(1_000_000_000...10_000_000_000).to_s
    end
  end
end
