# frozen_string_literal: true

class PhoneNumberAuthentication
  class Authenticate
    class Result < Struct.new(:authentication, :success, :error_message)
      def success?
        success
      end

      def user
        authentication.user
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(otp:, password:, phone_number:)
      @otp = otp
      @password = password
      @phone_number = phone_number
    end

    def call
      self.authentication = PhoneNumberAuthentication.find_by(phone_number: phone_number)
      result = verify_auth
      if result.success?
        authentication.set_access_token
        authentication.invalidate_otp
        authentication.failed_attempts = 0
        authentication.save!
      end
      result
    end

    private

    attr_accessor :authentication
    attr_reader :otp, :password, :phone_number
    delegate :track_failed_attempt, to: :authentication

    def lockout_time
      USER_AUTH_LOCKOUT_IN_MINUTES.minutes
    end

    def verify_auth
      if authentication.nil?
        failure("login.error_messages.unknown_user")
      elsif authentication.locked_at
        if authentication.in_lockout_period?
          failure("login.error_messages.account_locked", minutes: authentication.minutes_left_on_lockout)
        else
          authentication.unlock
          verify_auth
        end
      elsif authentication.otp != otp
        track_failed_attempt
        failure("login.error_messages.invalid_otp")
      elsif !authentication.otp_valid?
        track_failed_attempt
        failure("login.error_messages.expired_otp")
      elsif !authentication.authenticate(password)
        track_failed_attempt
        failure("login.error_messages.invalid_password")
      else
        success
      end
    end

    def failure(message_key, opts = {})
      error_string = I18n.t(message_key, opts)
      Result.new(authentication, false, error_string)
    end

    def success
      Result.new(authentication, true, nil)
    end
  end
end
