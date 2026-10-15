# The user that call results from the voice agent are attributed to. CallResult requires a
# user, and a dedicated bot keeps AI calls separable from healthcare worker calls in reports.
class VoiceAgentUser < ImportUser
  BOT_PHONE_NUMBER_PREFIX = "voice-agent-"

  def self.bot_full_name
    "Simple Voice Agent"
  end

  def self.bot_sync_approval_reason
    "bot user for the voice agent"
  end

  def self.bot_phone_number(org_id)
    BOT_PHONE_NUMBER_PREFIX + super
  end
end
