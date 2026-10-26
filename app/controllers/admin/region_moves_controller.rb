# frozen_string_literal: true

require "tasks/scripts/move_region"

class Admin::RegionMovesController < AdminController
  before_action :authorize_power_user
  before_action :check_feature_enabled

  def index
    # Show history of recent moves (optional)
    authorize { current_admin.power_user? }
  end

  def new
    authorize { current_admin.power_user? }

    # Get all regions for reference
    @all_regions = Region.order(:name).pluck(:slug, :name, :region_type).map { |slug, name, type|
      {slug: slug, name: name, region_type: type}
    }

    # Build a lookup of region slug to its children
    # This avoids N+1 queries by doing it all in Ruby
    @regions_by_parent = {}

    # Get all regions with their parent paths and parent region
    all_regions_data = Region.where.not(region_type: "root")
      .order(:name)
      .pluck(:slug, :name, :region_type, "ltree2text(path)")

    # Build a mapping of ltree path parts to actual slugs
    path_to_slug = {}
    all_regions_data.each do |slug, _name, _region_type, path_text|
      path_parts = path_text.split(".")
      path_key = path_parts.last # Last part of path corresponds to this region
      path_to_slug[path_key] = slug
    end

    # Build parent-child relationships using actual slugs
    all_regions_data.each do |slug, name, region_type, path_text|
      path_parts = path_text.split(".")
      next if path_parts.length < 2

      # Parent is the second-to-last element in path
      parent_path_part = path_parts[-2]
      # Convert path part (with underscores) to actual slug (with hyphens)
      parent_slug = path_to_slug[parent_path_part]
      next unless parent_slug

      @regions_by_parent[parent_slug] ||= []
      @regions_by_parent[parent_slug] << {
        slug: slug,
        name: name,
        region_type: region_type
      }
    end
  end

  def preview
    authorize { current_admin.power_user? }

    # Check if parameters are present
    if params[:region_identifier].blank?
      flash[:alert] = "Please select a region to move"
      redirect_to new_admin_region_move_path and return
    end

    if params[:new_parent_identifier].blank?
      flash[:alert] = "Please select a parent region"
      redirect_to new_admin_region_move_path and return
    end

    @region = find_region(params[:region_identifier])
    @new_parent = find_region(params[:new_parent_identifier])

    if @region.blank?
      flash[:alert] = "Region not found: #{params[:region_identifier]}"
      redirect_to new_admin_region_move_path and return
    end

    if @new_parent.blank?
      flash[:alert] = "Parent region not found: #{params[:new_parent_identifier]}"
      redirect_to new_admin_region_move_path and return
    end

    begin
      @mover = MoveRegion.new(region_slug: @region.slug, new_parent_slug: @new_parent.slug)
      @preview_result = @mover.move!(dry_run: true)

      # Get list of facilities that will move
      @affected_facilities = if @region.region_type == "facility"
        [@region]
      else
        Region.where("path <@ ?::ltree", @region.path.to_s)
          .where(region_type: "facility")
          .order(:name)
          .limit(20)
      end
    rescue ArgumentError => e
      flash[:alert] = "Invalid move: #{e.message}"
      redirect_to new_admin_region_move_path and return
    rescue => e
      Rails.logger.error "Error in region move preview: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:alert] = "Error: #{e.message}"
      redirect_to new_admin_region_move_path and return
    end
  end

  def create
    authorize { current_admin.power_user? }

    # Check if parameters are present
    if params[:region_identifier].blank? || params[:new_parent_identifier].blank?
      flash[:alert] = "Please select both region and parent"
      redirect_to new_admin_region_move_path and return
    end

    @region = find_region(params[:region_identifier])
    @new_parent = find_region(params[:new_parent_identifier])

    if @region.blank? || @new_parent.blank?
      flash[:alert] = "Region or parent not found"
      redirect_to new_admin_region_move_path and return
    end

    begin
      mover = MoveRegion.new(region_slug: @region.slug, new_parent_slug: @new_parent.slug)
      @result = mover.move!(dry_run: false, skip_reporting_refresh: true)

      flash[:success] = "Successfully moved #{@region.name} to #{@new_parent.name}. Reports will be updated shortly."
      redirect_to new_admin_region_move_path
    rescue => e
      flash[:alert] = "Failed to move region: #{e.message}"
      redirect_to new_admin_region_move_path
    end
  end

  private

  def find_region(identifier)
    return nil if identifier.blank?
    Region.find_by(slug: identifier) || Region.find_by(name: identifier)
  end

  def authorize_power_user
    authorize { current_admin.power_user? }
  end

  def check_feature_enabled
    unless Flipper.enabled?(:region_moves, current_admin)
      flash[:alert] = "This feature is not enabled for your account"
      redirect_to root_path
    end
  end
end
