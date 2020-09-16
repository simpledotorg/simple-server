#
# Keeps the old user_permissions intact
# Only adds new information about User#access_level and related Access
#
# To use:
#
# require "tasks/scripts/create_accesses_from_permissions"
# > CreateAccessesFromPermissions.do
#
class CreateAccessesFromPermissions
  OLD_ACCESS_LEVELS_TO_NEW = {
    organization_owner: "manager",
    supervisor: "manager",
    sts: "manager",
    analyst: "viewer_reports_only",
    counsellor: "call_center",
    owner: "power_user"
  }.freeze

  def self.do(*args)
    new(*args).do
  end

  attr_reader :organization, :dryrun, :verbose

  def initialize(organization: Organization.find_by!(name: "IHCI"), dryrun: true, verbose: true)
    @organization = Organization.find_by!(id: organization)
    @dryrun = dryrun
    @verbose = verbose
  end

  def do
    log "Migrating admins for Organization: #{organization.name}."
    log "Total admins in #{organization.name}: #{admins.length}."
    log "Note that this script will not migrate admins with access_level as: 'custom'."

    unless admins.any?
      log "Skipping because there are no admins in #{organization.name}"
      return
    end

    if dryrun
      log "Dryrun. Aborting."
      return
    end

    log "Starting migration..."

    User.transaction do
      log "Assigning access levels..."
      assign_access_levels
      log "Finished assigning access levels."

      log "Assigning accesses..."
      assign_accesses
      log "Finished assigning accesses."
    end

    log "Did not migrate the following custom admins: ['#{admins_with_custom_permissions.join("', '")}']"
  end

  private

  def assign_access_levels
    admins_by_access_level.each do |access_level, admins|
      User.where(id: admins).update_all(access_level: OLD_ACCESS_LEVELS_TO_NEW[access_level])
    end
  end

  def assign_accesses
    admins_by_access_level.each do |access_level, admins|
      admins.each do |admin|
        admin.reload

        accesses = current_resources(access_level, admin).map { |r| {resource: r} }

        User.transaction do
          admin.accesses.delete_all
          admin.accesses.create!(accesses)
        end
      end
    end
  end

  def admins_by_access_level
    @admins_by_access_level ||=
      admins.each_with_object(init_admins_by_access_level) { |admin, by_access_level|
        access_level_to_permissions.each do |access_level, permissions|
          if current_permissions(admin).to_set == permissions.to_set
            by_access_level[access_level] << admin
          end
        end
      }
  end

  def admins_with_custom_permissions
    (admins.to_set - admins_by_access_level.values.flatten.to_set).map(&:id)
  end

  def init_admins_by_access_level
    Permissions::ACCESS_LEVELS.map { |access_level|
      [access_level[:name], []]
    }.to_h
  end

  def access_level_to_permissions
    Permissions::ACCESS_LEVELS.map { |access_level|
      [access_level[:name], access_level[:default_permissions]]
    }.to_h
  end

  def current_permissions(admin)
    admin
      .user_permissions
      .map(&:permission_slug)
      .map(&:to_sym)
  end

  def current_resources(access_level, admin)
    # For the following access_levels, CohortReport serves as a proxy for FG-accesses:
    # - supervisor
    # - sts
    # - analyst
    if [:supervisor, :sts, :analyst].include?(access_level)
      return CohortReport::FacilityGroupPolicy::Scope.new(admin, FacilityGroup).resolve
    end

    # For the following access_levels, OverdueList policy serves as a proxy for FG-accesses:
    # - counsellor
    if [:counsellor].include?(access_level)
      return FacilityGroup.where(facilities: OverdueList::FacilityPolicy::Scope.new(admin, Facility).resolve)
    end

    # For the following access_levels, we can simply return the organization:
    # - organization_owner
    if [:organization_owner].include?(access_level)
      return [organization]
    end

    # Owners can't have any accesses
    [] if access_level.eql?(:owner)
  end

  def admins
    User.admins.where(organization: organization).where(access_level: nil)
  end

  def log(data)
    return unless verbose

    data_with_time = "[#{Time.current.strftime("%d.%b.%Y | %-k:%M:%S")}] #{data}"
    Rails.logger.info(data_with_time)
  end
end
