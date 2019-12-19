module CreateAdminUser
  def self.create_owner(name, email, password)
    user = User.create!(full_name: name, device_created_at: Time.now, device_updated_at: Time.now,
                        sync_approval_status: 'denied', sync_approval_status_reason: 'User is an admin', role: 'owner')
    user.email_authentications.create!(email: email, password: password)
    permissions = Permissions::ACCESS_LEVELS.find { |level| level[:name] == :owner }[:default_permissions]
    permissions.each { |permission| user.user_permissions.create!(permission_slug: permission) }
    user
  end
end
