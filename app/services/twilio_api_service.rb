# See https://www.twilio.com/docs/iam/test-credentials#test-sms-messages-parameters-From
# https://www.twilio.com/docs/whatsapp/sandbox#what-is-the-twilio-sandbox-for-whatsapp
# Twilio does not offer a true sandbox environment that separates logs from production.
# Instead, they build mocked TO/FROM numbers into the gem. So by using different TO/FROM
# numbers you can force different response types. To have a fully functional sandbox environment
# with its own logging, you would need to set up a different Twilio account and use those credentials.
#
# ERROR HANDLING: This service raises any errors related to the Twilio API as an exception.
# This is to allow background jobs to retry in case of network/limit errors.
# The error object contains the reason of failure if it was due to a known twilio error.
# The users of this service should use it to handle known errors properly.

class TwilioApiService
  def initialize
  end

end
