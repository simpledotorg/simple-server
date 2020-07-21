module RoleScopedRegions
  def facility_groups(role: :write)
    roles = if role == :write
      ["super_admin", "admin"]
    else
      ["super_admin", "admin", "analyst"]
    end
    sql = <<-SQL
      SELECT facility_groups.* from facility_groups
      INNER JOIN organizations
        ON facility_groups.organization_id = organizations.id
      INNER JOIN roles
        ON roles.resource_type = 'Organization'
        AND roles.resource_id = organizations.id
      WHERE roles.user_id = :user_id
        AND roles.name in (:roles)

      UNION

      SELECT facility_groups.* from facility_groups
      INNER JOIN roles
        ON roles.resource_type = 'FacilityGroup'
        AND roles.resource_id = facility_groups.id
      WHERE roles.user_id = :user_id
        AND roles.name in (:roles)
    SQL
    ids = FacilityGroup.find_by_sql([sql, {roles: roles, user_id: id}]).pluck(:id)
    FacilityGroup.where(id: ids)
  end

  def facilities(role: :write)
    roles = if role == :write
      ["super_admin", "admin"]
    else
      ["super_admin", "admin", "analyst"]
    end
    sql = <<-SQL
      SELECT facilities.* FROM facilities
      INNER JOIN facility_groups
        ON facility_groups.id = facilities.facility_group_id
      INNER JOIN organizations
        ON facility_groups.organization_id = organizations.id
      INNER JOIN roles
        ON roles.resource_type = 'Organization'
        AND roles.resource_id = organizations.id
      WHERE roles.user_id = :user_id
        AND roles.name in (:roles)

      UNION

      SELECT facilities.* FROM facilities
      INNER JOIN facility_groups
        ON facility_groups.id = facilities.facility_group_id
      INNER JOIN roles
        ON roles.resource_type = 'FacilityGroup'
        AND facility_groups.id = roles.resource_id
      WHERE roles.user_id = :user_id
        AND roles.name in (:roles)

      UNION

      SELECT facilities.* FROM facilities
      INNER JOIN roles
        ON roles.resource_type = 'Facility'
        AND roles.resource_id = facilities.id
      WHERE roles.user_id = :user_id
        AND roles.name in (:roles)

    SQL
    ids = Facility.find_by_sql([sql, {roles: roles, user_id: id}]).pluck(:id)
    Facility.where(id: ids)
  end
end