# frozen_string_literal: true

module CreateAdminUser
  def self.create_owner(name, email, password)
    user = User.create!(full_name: name,
      device_created_at: Time.now,
      device_updated_at: Time.now,
      sync_approval_status: "denied",
      sync_approval_status_reason: "User is an admin",
      role: "Power User",
      access_level: :power_user)
    user.email_authentications.create!(email: email, password: password)
    user
  end
end
