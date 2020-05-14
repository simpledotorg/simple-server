class PhoneNumberAuthentication
  class Authenticate
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
      when authentication.otp != otp
        failure('login.error_messages.invalid_otp')
      when !authentication.otp_valid?
        failure('login.error_messages.expired_otp')
      when !authentication.authenticate(password)
        failure('login.error_messages.invalid_password')
      else
        success
      end
    end

    def failure(message_key)
      error_string = I18n.t(message_key)
      Result.new(authentication, false, error_string)
    end

    def success
      Result.new(authentication, true, nil)
    end

  end
end