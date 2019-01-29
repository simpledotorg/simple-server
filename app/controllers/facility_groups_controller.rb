class FacilityGroupsController < AdminController
  def show
    skip_authorization

    @users_requesting_approval = policy_scope(User).requested_sync_approval

    @organization = Organization.friendly.find(params[:organization_id])
    @facility_group = FacilityGroup.friendly.find(params[:id])

    Groupdate.time_zone = "New Delhi"

    @days_previous = 20
    @months_previous = 8

    @facilities = @facility_group.facilities
    @visits_by_facility = visits_by_facility(@facility_group)
    @visits_by_facility_user = visits_by_facility_user(@facility_group)
    @visits_by_facility_user_day = visits_by_facility_user_day(@facility_group)
    @visits_by_facility_month = visits_by_facility_month(@facility_group)
    @new_patients_by_facility = new_patients_by_facility
    @new_patients_by_facility_month = new_patients_by_facility_month
    @control_rate_by_facility = control_rate_by_facility

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  private

  def blood_pressures_in_facility_group(facility_group)
    BloodPressuresQuery.new.for_facility_group(facility_group)
  end

  def visits_by_facility(facility_group)
    CountQuery.new(blood_pressures_in_facility_group(facility_group))
      .distinct_count('patient_id', group_by_columns: :facility_id)
  end

  def visits_by_facility_user(facility_group)
    CountQuery.new(blood_pressures_in_facility_group(facility_group))
      .distinct_count('patient_id', group_by_columns: [:facility_id, :user_id])
  end

  def visits_by_facility_user_day(facility_group)
    CountQuery.new(blood_pressures_in_facility_group(facility_group)).distinct_count(
      'patient_id',
      group_by_columns: [:facility_id, :user_id],
      group_by_period: { period: :day, column: :device_created_at, options: { last: @days_previous + 1 } })
  end

  def visits_by_facility_month(facility_group)
    CountQuery.new(blood_pressures_in_facility_group(facility_group)).distinct_count(
      'patient_id',
      group_by_columns: [:facility_id],
      group_by_period: { period: :month, column: :device_created_at, options: { last: @days_previous + 1 } })
  end

  def new_patients_by_facility
    CountQuery.new(Facility.joins(:patients).distinct('patients.id'))
      .distinct_count('patients.id', group_by_columns: 'facilities.id')
  end

  def new_patients_by_facility_month
    CountQuery.new(Facility.joins(:patients).distinct('patients.id'))
      .distinct_count(
        'patients.id',
        group_by_columns: 'facilities.id',
        group_by_period: { period: :month, column: 'patients.device_created_at', options: { last: @months_previous + 1 } })
  end

  def control_rate_by_facility
    control_rate = {}

    hypertensive_patients_by_facility.each do |facility_id, patient_ids|
      numerator = controlled_patients_for_facility(facility_id, patient_ids).size
      denominator = patient_ids.size
      control_rate[facility_id] = numerator.to_f / denominator unless denominator == 0
    end

    control_rate
  end

  def hypertensive_patients_by_facility(since: Time.new(0), upto: Time.now.in_time_zone("New Delhi"))
    hypertensive_patients = {}

    BloodPressure.hypertensive
      .select(:facility_id, 'array_agg(distinct(patient_id)) as hypertensive_patient_ids')
      .where("created_at >= ?", since)
      .where("created_at <= ?", upto)
      .group(:facility_id)
      .each { |record| hypertensive_patients[record.facility_id] = record.hypertensive_patient_ids }

    hypertensive_patients
  end

  def controlled_patients_for_facility(facility_id, patient_ids)
    BloodPressure.select('distinct on (patient_id) *')
      .where(facility_id: facility_id)
      .where(patient: patient_ids)
      .order(:patient_id, created_at: :desc)
      .select { |blood_pressure| blood_pressure.under_control? }
      .map(&:patient_id)
  end
end

