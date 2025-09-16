module OneOff
  module Opensrp
    module Deduplicators
      class ForPatient < ForMutableEntity
        # With these, we don't need to do anything because we are merging
        # forward. Since some of the attributes here are required from the API
        # spec, it is guaranteed to be present during the merge
        CHOOSING_NEW = %i[
          full_name
          updated_at
          gender
          status
          date_of_birth
        ].freeze

        # These are information we believe should be kept the same as the old
        # record for dsahboard purposes.
        CHOOSING_OLD = %i[
          assigned_facility_id
          created_at
          eligible_for_reassignment
          recorded_at
          registration_facility_id
          registration_user_id
          reminder_consent
        ]

        # These are the information which do not have real bearing on numbers,
        # but we need to merge them together to get a holistic patient story
        CHOOSING_NON_NULL = %i[
          address_id
          contacted_by_counsellor
          could_not_contact_reason
          deleted_at
          deleted_by_user_id
          deleted_reason
        ]

        def initialize old_id, new_id
          super(old_id, new_id)
          @needs_manual_merge = []
        end

        def merge
          new_patient.tap do |patient|
            merge_old(patient, old_patient, CHOOSING_OLD)
            merge_non_null(patient, old_patient, CHOOSING_NON_NULL)

            # For all which could not be merged automatically during the
            # non-null merge... perfer the newer value. — which is a no-op effectively
            merge_new(patient, old_patient, @needs_manual_merge)

            # Merge age as a special case
            merge_age(patient)
          end
        end

        private

        def merge_age(patient)
          # Age consists of three columns: age, date_of_birth, and age_updated_at
          # For date_of_birth...
          #   this is required from the API, so this prefers the new
          # For age
          #   calculate this from the new date_of_birth
          # For age_updated_at
          #   set this to now()

          patient.age = Date.today.year - patient.date_of_birth.year
          patient.age_updated_at = Time.now
        end
      end
    end
  end
end
