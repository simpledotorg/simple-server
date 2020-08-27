require "ostruct"

class AdminAccessPresenter < SimpleDelegator
  attr_reader :admin

  def initialize(admin)
    @admin = admin
    super
  end

  def display_access_level
    OpenStruct.new(UserAccess::LEVELS.fetch(admin.access_level.to_sym))
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end

  def access_tree(opts)
    AccessTree.new(admin, opts)
  end

  class AccessTree
    attr_reader :admin

    def initialize(admin, opts)
      @admin = admin

      if opts[:user_being_edited].present?
        @user_being_edited = opts[:user_being_edited]
        @editing = true
      end
    end

    def facilities(facility_group)
      accessible_facilities
        .where(facility_group: facility_group)
        .map do |facility|

        info = {
          pre_selected: pre_selected?(:facility, facility)
        }

        [facility, OpenStruct.new(info)]
      end.to_h
    end

    def facility_groups(organization)
      accessible_facilities
        .where(facility_groups: {organization: organization})
        .flat_map(&:facility_group)
        .map do |facility_group|

        info = {
          accessible_facility_count: 1,
          total_facility_count: facility_group.facilities.size,
          pre_selected: pre_selected?(:facility_group, facility_group)
        }

        [facility_group, OpenStruct.new(info)]
      end.to_h
    end

    def organizations
      accessible_facilities
        .flat_map(&:organization)
        .map do |organization|

        info = {
          accessible_facility_group_count: facility_groups(organization).keys.size,
          total_facility_group_count: organization.facility_groups.size,
          pre_selected: pre_selected?(:organization, organization)
        }

        [organization, OpenStruct.new(info)]
      end.to_h
    end

    private

    attr_reader :user_being_edited

    def accessible_facilities
      @accessible_facilities ||=
        admin.accessible_facilities(:view).includes(facility_group: :organization)
    end

    # if we're editing an existing user,
    # we pre-apply their access to the records that the admin can see
    def pre_selected?(model, record)
      if editing?
        user_being_edited.can?(:view, model, record)
      else
        false
      end
    end

    def editing?
      @editing
    end
  end
end
