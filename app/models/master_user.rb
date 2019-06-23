class MasterUser < ApplicationRecord

  AUTHENTICATION_TYPES = {
    email_authentication: 'EmailAuthentication',
    phone_number_authentication: 'PhoneNumberAuthentication'
  }

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  enum role: {
    nurse: 'nurse',
    owner: 'owner',
    organization_owner: 'organization_owner',
    supervisor: 'supervisor',
    counsellor: 'counsellor',
    analyst: 'analyst'
  }

  has_many :user_authentications
  has_many :email_authentications, through: :user_authentications, source: :authenticatable, source_type: 'EmailAuthentication'
  has_many :user_permissions, foreign_key: :user_id

  validates :full_name, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  delegate :email, :password, to: :email_authentication, allow_nil: true

  DEFAULT_PERMISSIONS_FOR_ROLE = {
    nurse: [],
    owner: [
      :can_manage_all_organizations,
      :can_manage_all_protocols,
      :can_manage_audit_logs,
      :can_access_patient_information_for_all_organizations,
      :can_access_appointment_information_for_all_organizations,
      :can_download_overdue_list_for_all_organizations,
      :can_approve_all_users
    ],
    organization_owner: [
      :can_manage_an_organization,
      :can_access_patient_information_for_organization,
      :can_access_appointment_information_for_organization,
      :can_download_overdue_list_for_organization,
      :can_approve_users_for_organization
    ],
    supervisor: [
      :can_manage_a_facility_group,
      :can_approve_users_for_facility_group
    ],
    counsellor: [
      :can_access_appointment_information_for_facility_group,
      :can_access_patient_information_for_facility_group
    ],
    analyst: [],
  }

  DEFAULT_SYNC_APPROVAL_DENIAL_STATUS = 'User does not need to sync'.freeze

  def email_authentication
    email_authentications.first
  end

  def phone_number_authentication
    user_authentication_of_type(AUTHENTICATION_TYPES[:phone_number_authentication])
  end

  def registration_facility_id
    return unless phone_number_authentication.present?
    phone_number_authentication.registration_facility_id
  end

  def authorized?(permission_slug, resource: nil)
    user_permissions.find_by(permission_slug: permission_slug, resource: resource).present?
  end

  def has_permission?(permission_slug)
    user_permissions.find_by(permission_slug: permission_slug).present?
  end

  def assign_permissions(permissions)
    permissions.each do |permission|
      permission = [permission] unless permission.is_a?(Array)
      self.user_permissions.new(
        permission_slug: permission.first,
        resource: permission.second)
    end
    self.save
  end

  def self.requested_sync_approval
    where(sync_approval_status: :requested)
  end

  private

  def user_authentication_of_type(authenticatable_type)
    master_user_authentications.find_by(authenticatable_type: authenticatable_type)
  end
end
