class Admin::FixZoneDataController < AdminController
  CANONICAL_BLOCKS = YAML.load_file("config/data/canonical_blocks_ihci.yml")

  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    canonical_blocks = CANONICAL_BLOCKS.uniq.compact.sort.join("\n")
    blocks = Facility.all.pluck(:zone).uniq.compact.sort.reject(&:empty?).join("\n")

    @diff = Diffy::Diff.new(blocks, canonical_blocks)
    @facility_count = Facility.group(:zone).count
  end

  def update
    authorize { current_admin.power_user? }

    Facility.where(zone: params[:old_block]).update(zone: params[:new_block])

    redirect_to admin_fix_zone_data_path
  end
end
