require "rails_helper"

RSpec.describe DashboardPolicy do
  let(:user) { create(:admin) }
  subject { described_class }

  shared_examples "grant permission" do |permission_slug|
    it "permits the user with #{permission_slug} permission" do
      create(:user_permission, user: user, permission_slug: permission_slug)
      expect(subject).to permit(user, :dashboard)
    end
  end


  shared_examples "deny permission" do |permission_slug|
    it "does not permits the user with #{permission_slug} permission" do
      create(:user_permission, user: user, permission_slug: permission_slug)
      expect(subject).not_to permit(user, :dashboard)
    end
  end


  permissions :show? do
    allowed_permissions = [:view_cohort_reports, :approve_health_workers]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :overdue_list? do
    allowed_permissions = [:view_overdue_list]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :adherence_follow_up? do
    allowed_permissions = [:view_adherence_follow_up_list]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage_organizations? do
    allowed_permissions = [:manage_organizations]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage_facilities? do
    allowed_permissions = [:manage_facilities, :manage_facility_groups]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage_protocols? do
    allowed_permissions = [:manage_protocols]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage_admins? do
    allowed_permissions = [:manage_admins]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage_users? do
    allowed_permissions = [:approve_health_workers]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end

  permissions :manage? do
    allowed_permissions = [
      :manage_admins,
      :manage_organizations,
      :manage_facility_groups,
      :manage_facilities,
      :manage_protocols,
      :approve_health_workers
    ]
    other_permissions = Permissions::ALL_PERMISSIONS.keys - allowed_permissions

    allowed_permissions.each { |slug| include_examples "grant permission", slug }
    other_permissions.each { |slug| include_examples "deny permission", slug }
  end
end
