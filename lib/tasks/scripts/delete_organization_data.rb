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
    patients = Patient.with_discarded.where(registration_facility_id: facilities)
    address_ids = patients.pluck(:address_id)

    Appointment.with_discarded.where(patient_id: patients).delete_all
    BloodPressure.with_discarded.where(patient_id: patients).delete_all
    BloodSugar.with_discarded.where(patient_id: patients).delete_all
    MedicalHistory.with_discarded.where(patient_id: patients).delete_all
    PrescriptionDrug.with_discarded.where(patient_id: patients).delete_all

    patient_phone_numbers = PatientPhoneNumber.with_discarded.where(patient_id: patients)
    ExotelPhoneNumberDetail.where(patient_phone_number_id: patient_phone_numbers).delete_all
    patient_phone_numbers.delete_all

    patient_business_identifiers = PatientBusinessIdentifier.with_discarded.where(patient_id: patients)
    PassportAuthentication.where(patient_business_identifier: patient_business_identifiers).delete_all
    patient_business_identifiers.with_discarded.delete_all

    encounters = Encounter.with_discarded.where(patient_id: patients)
    Observation.with_discarded.where(encounter_id: encounters).delete_all
    encounters.delete_all

    patients.delete_all
    Address.with_discarded.where(id: address_ids).delete_all
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
