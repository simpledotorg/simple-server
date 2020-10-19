class Admin::FixZoneDataController < AdminController
  CANONICAL_ZONES = YAML.load_file("config/data/canonical_blocks_ihci.yml")

  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    canonical_zones = CANONICAL_ZONES.uniq.compact.sort.join("\n")
    zones = Facility.all.pluck(:zone).uniq.compact.sort.reject(&:empty?).join("\n")

    @diff = Diffy::Diff.new(zones, canonical_zones)
    @facility_count = Facility.group(:zone).count
  end

  def update
    authorize { current_admin.power_user? }

    Facility.where(zone: params[:old_zone]).update(zone: params[:new_zone])

    redirect_to admin_fix_zone_data_path
  end
end
