module Accessible
  extend ActiveSupport::Concern

  class NotAuthorizedError < StandardError
    attr_reader :action, :model

    def initialize(options = {})
      if options.is_a? String
        message = options
      else
        @action = options[:action]
        @model = options[:model]

        message = options.fetch(:message) { "not allowed to #{action} this #{model}" }
      end

      super(message)
    end
  end

  class AuthorizationNotPerformedError < StandardError; end

  ACCESS_LEVELS = {
    viewer: {
      id: :viewer,
      name: "View: Everything",
      grant_access: [],
      description: "Can view stuff"
    },

    manager: {
      id: :manager,
      name: "Manager",
      grant_access: [:viewer, :manager],
      description: "Can manage stuff"
    },

    power_user: {
      id: :power_user,
      name: "Power User",
      grant_access: [:viewer, :manager, :power_user],
      description: "Can manage everything"
    }
  }

  included do
    has_many :accesses, dependent: :destroy
    enum access_level: ACCESS_LEVELS.map { |level, meta| [level, meta[:id].to_s] }.to_h, _suffix: :access
    # Revive this validation once all users are migrated to the new permissions system:
    # validates :access_level, presence: true, if: -> { email_authentication.present? }
  end

  def accessible_organizations(action)
    return Organization.all if power_user?
    accesses.organizations(action)
  end

  def accessible_facility_groups(action)
    return FacilityGroup.all if power_user?
    accesses.facility_groups(action)
  end

  def accessible_facilities(action)
    return Facility.all if power_user?
    accesses.facilities(action)
  end

  def can?(action, model, record = nil)
    return true if power_user?
    accesses.can?(action, model, record)
  end

  def access_tree(action)
    facilities = accessible_facilities(action).includes(facility_group: :organization)

    facility_tree =
      facilities
        .map { |facility| [facility, {can_access: true}] }
        .to_h

    facility_group_tree =
      facilities
        .map(&:facility_group)
        .map { |fg|
          facilities_in_facility_group =
            facility_tree.select { |facility, _| facility.facility_group == fg }

          [fg,
            {
              can_access: can?(action, :facility_group, fg),
              facilities: facilities_in_facility_group,
              total_facilities: fg.facilities.size
            }
          ]
        }
        .to_h

    organization_tree =
      facilities
        .map(&:facility_group)
        .map(&:organization)
        .map { |org|
          facility_groups_in_org =
            facility_group_tree.select { |facility_group, _| facility_group.organization == org }

          [org,
            {
              can_access: can?(action, :organization, org),
              facility_groups: facility_groups_in_org,
              total_facility_groups: org.facility_groups.size
            }
          ]
        }
        .to_h

    {organizations: organization_tree}
  end

  def grantable_access_levels
    ACCESS_LEVELS.slice(*ACCESS_LEVELS[access_level.to_sym][:grant_access])
  end

  def grant_access(user, selected_facility_ids)
    raise NotAuthorizedError unless grantable_access_levels.key?(user.access_level.to_sym)
    resources = prepare_access_resources(selected_facility_ids)
    # if the user couldn't prepare any resources means that they shouldn't have had access to this operation at all
    raise NotAuthorizedError if resources.empty?
    user.accesses.create!(resources)
  end

  def power_user?
    power_user_access? && email_authentication.present?
  end

  private

  def prepare_access_resources(selected_facility_ids)
    selected_facilities = Facility.where(id: selected_facility_ids)
    resources = []

    selected_facilities.group_by(&:organization).each do |org, selected_facilities_in_org|
      if can?(:manage, :organization, org) && org.facilities == selected_facilities_in_org
        resources << {resource: org}
        selected_facilities -= selected_facilities_in_org
      end
    end

    selected_facilities.group_by(&:facility_group).each do |fg, selected_facilities_in_fg|
      if can?(:manage, :facility_group, fg) && fg.facilities == selected_facilities_in_fg
        resources << {resource: fg}
        selected_facilities -= selected_facilities_in_fg
      end
    end

    selected_facilities.each do |f|
      resources << {resource: f} if can?(:manage, :facility, f)
    end

    resources.flatten
  end
end
