#
# Keeps the old user_permissions intact
# Only adds new information about User#access_level and related Access
#
# To use:
# require "tasks/scripts/migrate_user_permissions_to_accesses"
#
class UserPermissionsToAccesses
  class << self
    OLD_ACCESS_LEVELS_TO_NEW = {
      organization_owner: "manager",
      supervisor: "manager",
      sts: "manager",
      analyst: "view_reports_only",
      counsellor: "call_center",
      owner: "power_user"
    }.freeze

    def migrate(dryrun: true)
      log "Running in dryrun mode..." if dryrun
      log "Migrating admins for Organization: #{organization_name}."
      log "Total admins in #{organization_name}: #{admins.length}."
      log "Note that this script will not migrate admins with access_level as: 'custom'."

      unless dryrun
        log "Starting migration..."

        User.transaction do
          log "Assigning access levels..."
          assign_access_levels
          log "Finished assigning access levels."

          log "Assigning accesses..."
          assign_accesses
          log "Finished assigning accesses."
        end
      end
    end

    def assign_accesses
      admins_by_access_level
        .except(:custom)
        .each do |_access_level, admins|
        admins.each do |admin|
          facility_group_accesses = current_facility_groups(admin).map { |fg| {resource: fg} }
          admin.accesses.create!(facility_group_accesses)
        end
      end
    end

    def assign_access_levels
      admins_by_access_level
        .except(:custom) # skip custom access levels
        .each { |access_level, admins| admins.update_all(access_level: OLD_ACCESS_LEVELS_TO_NEW[access_level]) }
    end

    def admins_by_access_level
      admins.each_with_object(init_per_access_level_list) do |admin, by_access_level|
        access_level_to_permissions.each do |access_level, permissions|
          if current_permissions(admin).to_set == permissions.to_set
            by_access_level[access_level] << admin
          else
            by_access_level[:custom] << admin
          end
        end
      end
    end

    def access_level_to_permissions
      Permissions::ACCESS_LEVELS.map { |access_level|
        [access_level[:name], access_level[:default_permissions]]
      }.to_h
    end

    def init_per_access_level_list
      Permissions::ACCESS_LEVELS.map { |access_level|
        [access_level[:name], []]
      }.to_h
    end

    def current_permissions(admin)
      admin
        .user_permissions
        .map(&:permission_slug)
        .map(&:to_sym)
    end

    def current_facility_groups(admin)
      # Using CohortReport as a proxy to get FG access since that permission is shared across all access levels
      CohortReport::FacilityGroupPolicy::Scope.new(admin, FacilityGroup).resolve
    end

    def admins
      User.admins.where(organization: organization)
    end

    def organization
      Organization.where(name: organization_name)
    end

    def organization_name
      "IHCI"
    end

    def log(data)
      data_with_time = "[#{Time.current.strftime("%d.%b.%Y | %-k:%M:%S")}] #{data}"
      Rails.logger.info(data_with_time)
    end
  end
end
