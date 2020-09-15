#
# Keeps the old user_permissions intact
# Only adds new information about User#access_level and related Access
#
# To use:
# require "tasks/scripts/migrate_user_permissions_to_accesses"
# CreateAccessesFromPermissions.do
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

  attr_reader :organization_name, :dryrun, :verbose

  def initialize(organization_name: "IHCI", dryrun: false, verbose: true)
    @organization_name = organization_name
    @dryrun = dryrun
    @verbose = verbose
  end

  def do
    log "Migrating admins for Organization: #{organization_name}."
    log "Total admins in #{organization_name}: #{admins.length}."
    log "Note that this script will not migrate admins with access_level as: 'custom'."

    if dryrun
      log "Dryrun. Aborting."
      return
    end

    log "Starting migration..."

    log "Assigning access levels..."
    assign_access_levels
    log "Finished assigning access levels."

    log "Assigning accesses..."
    assign_accesses
    log "Finished assigning accesses."

    log "Did not migrate the following custom admins: #{admins_with_custom_permissions.map(&:id).join(", ")}"
    log "Please manually take care of admins who need to have Organization-level permissions."
  end

  private

  def assign_accesses
    admins_by_access_level
      .except(:custom) # skip custom access levels
      .each do |access_level, admins|
      admins.each do |admin|
        accesses = current_resources(access_level, admin).map { |r| {resource: r} }
        admin.accesses.create!(accesses)
      end
    end
  end

  def assign_access_levels
    admins_by_access_level
      .except(:custom) # skip custom access levels
      .each do |access_level, admins|

      User.where(id: admins).update_all(access_level: OLD_ACCESS_LEVELS_TO_NEW[access_level])
    end
  end

  def admins_by_access_level
    admins.each_with_object(init_admins_by_access_level) do |admin, by_access_level|
      access_level_to_permissions.each do |access_level, permissions|
        if current_permissions(admin).to_set == permissions.to_set
          by_access_level[access_level] << admin
        else
          by_access_level[:custom] << admin
        end
      end
    end
  end

  def admins_with_custom_permissions
    admins_by_access_level[:custom]
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

    # For the follow access_levels, OverdueList policy serves as a proxy for FG-accesses:
    # - counsellor
    if [:counsellor].include?(access_level)
      return FacilityGroup.where(facilities: OverdueList::FacilityPolicy::Scope.new(admin, Facility).resolve)
    end

    # For the follow access_levels, we can simply return the organization:
    # - organization_owner
    # - owner
    if [:organization_owner].include?(access_level)
      return organization
    end

    # Owners can't have any accesses
    [] if access_level.eql?(:owner)
  end

  def admins
    User.admins.where(organization: organization)
  end

  def organization
    @organization ||= Organization.where(name: organization_name)
  end

  def log(data)
    return unless verbose

    data_with_time = "[#{Time.current.strftime("%d.%b.%Y | %-k:%M:%S")}] #{data}"
    Rails.logger.info(data_with_time)
  end
end
