class EmailSubjectPrefixInterceptor
  def self.delivering_email(message)
    prefix = ENV.fetch("EMAIL_SUBJECT_PREFIX")
    message.subject.prepend("#{prefix} ")
  end

end

if ENV["EMAIL_SUBJECT_PREFIX"].present?
  ActionMailer::Base.register_interceptor(EmailSubjectPrefixInterceptor)
end
