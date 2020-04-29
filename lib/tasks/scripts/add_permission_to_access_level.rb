# frozen_string_literal: true

# Creates the specified permission for users who have the specified access_level
class AddPermissionToAccessLevel

  attr_reader :permission, :access_level

  def initialize(permission, access_level)
    @permission = permission
    @access_level = access_level
  end

  def valid_permission?
    true if Permissions::ALL_PERMISSIONS[permission] && valid_permission_for_access_level?
  end

  def users_with_access_level
    users = User.joins(:user_permissions).uniq
    users.select(&:user_has_access_level?)
  end

  def create_permissions
    permission = Permissions::ALL_PERMISSIONS[permission]
    users_with_access_level.each do |user|
      UserPermission.create(user: user,
                            permission_slug: permission[:slug],
                            resource_type: [])
    end
  end

  private

  def user_has_access_level?(user)
    user_permissions = user.user_permissions.map(&:permission_slug).uniq.sort.map(&:to_sym)
    access_level_permissions = Permissions::ACCESS_LEVELS.select { |level| level[:name] == access_level }
                                                         .first[:default_permissions]
                                                         .uniq
                                                         .sort

    user_permissions == access_level_permissions - [permission]
  end

  def valid_permission_for_access_level?
    access_level_map = Permissions::ACCESS_LEVELS.select { |level| level[:name] == access_level }.first

    true if access_level_map && access_level_map[:default_permissions].include?(permission)
  end
end
