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

  def valid?
    return true if permission && valid_permission_for_access_level?

    false
  end

  def create
    return false unless valid?

    users.each do |user|
      permission_resources(user).each do |resource|
        UserPermission.find_or_create_by!(user: user,
                                          permission_slug: permission[:slug],
                                          resource_type: resource[:resource_type],
                                          resource_id: resource[:resource_id])
      end
    end
  end

  private

  def users
    users = User.includes(:user_permissions).where.not(user_permissions: { id: nil })
    users.select(&method(:eligible?))
  end

  def permission_resources(user)
    return [{ resource_type: nil, resource_id: nil }] if permission[:resource_priority] == [:global]

    case permission_resource_type(user.user_permissions.map(&:resource_type).uniq)
    when :facility_group
      user.user_permissions.where(resource_type: 'FacilityGroup').map(&method(:permission_resource)).uniq
    when :organization
      user.user_permissions.where(resource_type: 'Organization').map(&method(:permission_resource)).uniq
    when :global
      [{ resource_type: nil, resource_id: nil }]
    else
      []
    end
  end

  def permission_resource(resource)
    resource.slice(:resource_type, :resource_id)
  end

  def permission_resource_type(user_resource_types)
    return :facility_group if permission[:resource_priority].include?(:facility_group) &&
                              user_resource_types.include?('FacilityGroup')

    return :organization if permission[:resource_priority].include?(:organization) &&
                            user_resource_types.include?('Organization')

    :global if permission[:resource_priority].include?(:global) &&
               user_resource_types.include?(nil)
  end

  def eligible?(user)
    user_permissions = user.user_permissions.map(&:permission_slug).uniq.sort.map(&:to_sym)
    required_permissions = permission[:required_permissions]
    access_level_permissions = access_level[:default_permissions].uniq.sort

    user_permissions == access_level_permissions - [permission_name] &&
      (user_permissions & required_permissions) == required_permissions
  end

  def valid_permission_for_access_level?
    access_level && access_level[:default_permissions].include?(permission_name)
  end
end
