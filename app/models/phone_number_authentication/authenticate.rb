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
      authentication = PhoneNumberAuthentication.find_by(phone_number: phone_number)
      result = verify(authentication)
      if result.success?
        authentication.set_access_token
        authentication.invalidate_otp
        authentication.save
      end
      result
    end

    private

    attr_reader :otp, :password, :phone_number

    def verify(authentication)
      error_string = case
      when !authentication.present?
        I18n.t('login.error_messages.unknown_user')
      when authentication.otp != otp
        I18n.t('login.error_messages.invalid_otp')
      when !authentication.otp_valid?
        I18n.t('login.error_messages.expired_otp')
      when !authentication.authenticate(password)
        I18n.t('login.error_messages.invalid_password')
      end

      if error_string
        Result.new(authentication, false, error_string)
      else
        Result.new(authentication, true, nil)
      end
    end
  end
end