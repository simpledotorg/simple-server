class Admin::FixBlockDataController < AdminController
  CANONICAL_BLOCKS = YAML.load_file("config/data/canonical_blocks.yml")
  PROD_BLOCKS = YAML.load_file("config/data/prod_blocks.yml")

  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    canonical_blocks = CANONICAL_BLOCKS.uniq.sort.compact
    blocks = Facility.all.pluck(:zone).uniq.sort.reject(&:empty?)

    @diff = Diffy::Diff.new(PROD_BLOCKS.join("\n") || blocks.join("\n"), canonical_blocks.join("\n"))
    @facility_count = Facility.group(:zone).count
  end

  def update
    authorize { current_admin.power_user? }

    Facility.where(zone: params[:old_block]).update(zone: params[:new_block])

    redirect_to admin_fix_block_data_path
  end
end
