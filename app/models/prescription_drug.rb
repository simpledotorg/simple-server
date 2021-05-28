class PrescriptionDrug < ApplicationRecord
  include Mergeable
  include Hashable

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id medicine_name dosage]

  enum frequency: {
    OD: "OD",
    BD: "BD",
    QDS: "QDS",
    TDS: "TDS"
  }, _prefix: true

  belongs_to :facility, optional: true
  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :teleconsultation, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :is_protocol_drug, inclusion: {in: [true, false]}
  validates :is_deleted, inclusion: {in: [true, false]}

  after_create_commit :log_medication_reminder_success

  scope :for_sync, -> { with_discarded }

  def self.prescribed_as_of(date)
    where("device_created_at <= ?", date.end_of_day)
      .where(%(prescription_drugs.is_deleted = false OR
              (prescription_drugs.is_deleted = true AND
               prescription_drugs.device_updated_at > ?)), date.end_of_day)
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(patient&.registration_user&.id),
     medicine_name: name,
     dosage: dosage}
  end

  private

  # this code should only be temporary, as it's part of monitoring a one-off experiment
  # https://app.clubhouse.io/simpledotorg/story/3642/remove-unnecessary-medication-reminder-code
  def log_medication_reminder_success
    experiment_membership = patient.treatment_group_memberships.find { |membership| membership.treatment_group.experiment.experiment_type == "medication_reminder" }
    return unless experiment_membership
    experiment = experiment_membership.treatment_group.experiment
    notification = patient.notifications.find_by(experiment_id: experiment.id)
    communication = notification.communications.find { |communication| communication.successful? }
    return unless communication
    time_till_visit = device_created_at - communication.detailable.delivered_on

    log_info = {
      class: self.class.name,
      msg: "log_medication_reminder_success",
      treatment_group_membership: experiment_membership.id, # for tracking patient without exposing patient id
      facility_id: facility.id,
      time_till_visit: time_till_visit
    }

    logger.info(log_info)
  end
end
