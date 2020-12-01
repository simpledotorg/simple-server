class DeleteOrganizationData
  def self.call(*args)
    new(*args).call
  end

  def initialize(organization)
    @organization = organization
    @facility_groups = FacilityGroup.with_discarded.where(organization: @organization)
    @facilities = Facility.with_discarded.where(facility_group: @facility_groups)
  end

  def call
    ActiveRecord::Base.transaction do
      delete_app_users
      delete_dashboard_users
      delete_patient_data
      delete_regions
      delete_facilities
      delete_facility_groups
      delete_organization
    end
  end

  private

  attr_reader :organization, :facility_groups, :facilities

  def delete_patient_data
    patients = Patient.with_discarded.where(registration_facility: facilities)
    patient_business_identifiers = PatientBusinessIdentifier.with_discarded.where(patient_id: patients)

    Address.with_discarded.where(patient_id: patients).destroy_all
    Appointment.with_discarded.where(patient_id: patients).destroy_all
    BloodPressure.with_discarded.where(patient_id: patients).destroy_all
    BloodSugar.with_discarded.where(patient_id: patients).destroy_all
    PassportAuthentication.with_discarded.where(patient_business_identifier: patient_business_identifiers).destroy_all
    patient_business_identifiers.with_discarded.destroy_all
    Observation.with_discarded.where(patient_id: patients).destroy_all
    Encounter.with_discarded.where(patient_id: patients).destroy_all
    MedicalHistory.with_discarded.where(patient_id: patients).destroy_all
    PrescriptionDrug.with_discarded.where(patient_id: patients).destroy_all
  end

  def delete_app_users
    User.with_discarded.where(registration_facility: facilities).destroy_all
    PhoneNumberAuthentication.with_discarded.where(registration_facility: facilities).destroy_all
  end

  def delete_dashboard_users
    User.with_discarded.where(organization_id: organization.id).destroy_all
  end

  def delete_regions
    Region.find_by(source_id: organization.id)&.self_and_descendants&.destroy_all
  end

  def delete_facilities
    facilities.destroy_all
  end

  def delete_facility_groups
    facility_groups.destroy_all
  end

  def delete_organization
    organization.destroy
  end
end
