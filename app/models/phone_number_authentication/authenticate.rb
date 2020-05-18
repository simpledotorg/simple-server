class PhoneNumberAuthentication
  class Authenticate
    MAX_FAILED_ATTEMPTS = 5
    LOCKOUT_TIME = 20.minutes

    class Result < Struct.new(:authentication, :success, :error_message)
      def success?
        self.success
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
        authentication.save
      end
      result
    end

    private

    attr_accessor :authentication
    attr_reader :otp, :password, :phone_number

    def verify_auth
      case
      when authentication.nil?
        failure('login.error_messages.unknown_user')
      when authentication.locked_at
        if authentication.locked_at >= LOCKOUT_TIME.ago
          minutes_left = (LOCKOUT_TIME - (Time.current - authentication.locked_at)) / 1.minute
          minutes_left = minutes_left.round
          failure("login.error_messages.account_locked", minutes: minutes_left)
        else
          unlock
          verify_auth
        end
      when authentication.otp != otp
        track_failed_attempt
        failure('login.error_messages.invalid_otp')
      when !authentication.otp_valid?
        track_failed_attempt
        failure('login.error_messages.expired_otp')
      when !authentication.authenticate(password)
        track_failed_attempt
        failure('login.error_messages.invalid_password')
      else
        success
      end
    end

    def unlock
      authentication.update!(locked_at: nil, failed_attempts: 0)
    end

    def track_failed_attempt
      authentication.increment!(:failed_attempts)
      if authentication.failed_attempts >= MAX_FAILED_ATTEMPTS
        authentication.update!(locked_at: Time.current)
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
