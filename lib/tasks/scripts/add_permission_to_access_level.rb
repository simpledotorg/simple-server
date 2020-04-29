# frozen_string_literal: true

# Creates the specified permission for users who have the specified access_level
class AddPermissionToAccessLevel

  attr_reader :permission_name, :access_level_name, :access_level, :permission

  def initialize(permission_name, access_level_name)
    @permission_name = permission_name
    @access_level_name = access_level_name
    @permission = Permissions::ALL_PERMISSIONS[permission_name]
    @access_level = Permissions::ACCESS_LEVELS.select { |level| level[:name] == access_level_name }.first
  end

  def valid_permission?
    true if permission && valid_permission_for_access_level?
  end

  def users
    users = User.includes(:user_permissions).where.not(user_permissions: { id: nil })
    users.select(&:user_is_a_match?)
  end

  def create_permissions
    users.each do |user|
      permission_resources(user).each do |resource|
        UserPermission.create(user: user,
                              permission_slug: permission[:slug],
                              resource_type: resource[:resource_type],
                              resource_id: resource[:resource_id])
      end
    end
  end

  private

  def permission_resources(user)
    return [{ resource_type: nil, resource_id: nil }] if permission[:resource_priority] == [:global]

    existing_resource_types = user.user_permissions.map(&:resource_type)

    case
    when permission[:resource_priority].include?(:facility_group) && existing_resource_types.include?('FacilityGroup')
      user.user_permissions.where(resource_type: 'FacilityGroup').map do |resource|
        { resource_type: resource.resource_type, resource_id: resource.resource_id }.uniq
      end
    when permission[:resource_priority].include?(:organization) && existing_resource_types.include?('Organization')
      user.user_permissions.where(resource_type: 'Organization').map do |resource|
        { resource_type: resource.resource_type, resource_id: resource.resource_id }.uniq
      end
    end
  end

  def user_is_a_match?(user)
    user_permissions = user.user_permissions.map(&:permission_slug).uniq.sort.map(&:to_sym)
    required_permissions = permission[:required_permissions]
    access_level_permissions = access_level[:default_permissions].uniq.sort

    user_permissions == access_level_permissions - [permission_name] &&
      (user_permissions & required_permissions) == required_permissions
  end

  def valid_permission_for_access_level?
    access_level && access_level[:default_permissions].include?(permission)
  end
end
