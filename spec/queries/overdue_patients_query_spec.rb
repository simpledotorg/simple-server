require "rails_helper"

RSpec.describe OverduePatientsQuery do
  timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
  this_month = timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0)

  around do |example|
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  context "count_patients_called" do
    it "should return count of overdue patients called" do
      facility = create(:facility)
      _user_1 = create(:user, registration_facility: facility)
      _user_2 = create(:user, registration_facility: facility)

      patient_1 = create(:patient, assigned_facility: facility)
      patient_2 = create(:patient, assigned_facility: facility)
      patient_3 = create(:patient, assigned_facility: facility)
      patient_4 = create(:patient, assigned_facility: facility)

      _call_result_1 = create(:call_result, patient: patient_1, device_created_at: this_month + 15.days)
      _call_result_1 = create(:call_result, patient: patient_2, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_3, device_created_at: this_month + 27.days)
      _call_result_1 = create(:call_result, patient: patient_4, device_created_at: this_month - 4.days)

      RefreshReportingViews.refresh_v2

      previous_month = Date.today - 1.month
      expected = {
        Period.month("#{Date::MONTHNAMES[previous_month.month]} #{Date.today.year}") => 3
      }

      expect(described_class.new.count_patients_called(facility.region, :month)).to eq(expected)
    end

    it "should return count of overdue patients called grouped by the group_by condition" do
      facility = create(:facility)
      user_1 = create(:user, registration_facility: facility)
      user_2 = create(:user, registration_facility: facility)

      patient_1 = create(:patient, assigned_facility: facility)
      patient_2 = create(:patient, assigned_facility: facility)
      patient_3 = create(:patient, assigned_facility: facility)
      patient_4 = create(:patient, assigned_facility: facility)

      _call_result_1 = create(:call_result, patient: patient_1, user: user_1, device_created_at: this_month + 15.days)
      _call_result_1 = create(:call_result, patient: patient_2, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_3, user: user_1, device_created_at: this_month + 27.days)
      _call_result_1 = create(:call_result, patient: patient_4, user: user_2, device_created_at: this_month + 4.days)

      RefreshReportingViews.refresh_v2

      previous_month = Date.today - 1.month
      expected = {
        Period.month("#{Date::MONTHNAMES[previous_month.month]} #{Date.today.year}") => {
          user_1.id => 3,
          user_2.id => 1
        }
      }

      expect(described_class.new.count_patients_called(facility.region, :month,
        group_by: :called_by_user_id)).to eq(expected)
    end

    it "should not include overdue patients who were not called" do
      facility = create(:facility)
      user_1 = create(:user, registration_facility: facility)
      user_2 = create(:user, registration_facility: facility)

      patient_1 = create(:patient, assigned_facility: facility)
      patient_2 = create(:patient, assigned_facility: facility)
      _patient_3 = create(:patient, assigned_facility: facility)
      patient_4 = create(:patient, assigned_facility: facility)

      _call_result_1 = create(:call_result, patient: patient_1, user: user_1, device_created_at: this_month + 15.days)
      _call_result_1 = create(:call_result, patient: patient_2, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_4, user: user_2, device_created_at: this_month + 4.days)

      RefreshReportingViews.refresh_v2

      previous_month = Date.today - 1.month
      expected = {
        Period.month("#{Date::MONTHNAMES[previous_month.month]} #{Date.today.year}") => {
          user_1.id => 2,
          user_2.id => 1
        }
      }

      expect(described_class.new.count_patients_called(facility.region, :month,
        group_by: :called_by_user_id)).to eq(expected)
    end

    it "should only include patients who were assigned to the facility" do
      facility_1 = create(:facility)
      facility_2 = create(:facility)
      user_1 = create(:user, registration_facility: facility_1)
      user_2 = create(:user, registration_facility: facility_2)

      patient_1 = create(:patient, assigned_facility: facility_1)
      patient_2 = create(:patient, assigned_facility: facility_1)
      patient_3 = create(:patient, assigned_facility: facility_1)
      patient_4 = create(:patient, assigned_facility: facility_2)

      _call_result_1 = create(:call_result, patient: patient_1, user: user_1, device_created_at: this_month + 15.days)
      _call_result_1 = create(:call_result, patient: patient_2, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_3, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_4, user: user_2, device_created_at: this_month + 4.days)

      RefreshReportingViews.refresh_v2

      previous_month = Date.today - 1.month
      expected = {
        Period.month("#{Date::MONTHNAMES[previous_month.month]} #{Date.today.year}") => {
          user_2.id => 1
        }
      }

      expect(described_class.new.count_patients_called(facility_2.region, :month,
        group_by: :called_by_user_id)).to eq(expected)
    end

    it "should include patients assigned to a facility regardless of which facility the user called from" do
      facility_1 = create(:facility)
      facility_2 = create(:facility)
      user_1 = create(:user, registration_facility: facility_1)
      user_2 = create(:user, registration_facility: facility_2)

      patient_1 = create(:patient, assigned_facility: facility_1)
      patient_2 = create(:patient, assigned_facility: facility_1)
      patient_3 = create(:patient, assigned_facility: facility_2)
      patient_4 = create(:patient, assigned_facility: facility_2)

      _call_result_1 = create(:call_result, patient: patient_1, user: user_1, device_created_at: this_month + 15.days)
      _call_result_1 = create(:call_result, patient: patient_2, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_3, user: user_1, device_created_at: this_month + 1.days)
      _call_result_1 = create(:call_result, patient: patient_4, user: user_2, device_created_at: this_month + 4.days)

      RefreshReportingViews.refresh_v2

      previous_month = Date.today - 1.month
      expected = {
        Period.month("#{Date::MONTHNAMES[previous_month.month]} #{Date.today.year}") => {
          user_1.id => 1,
          user_2.id => 1
        }
      }

      expect(described_class.new.count_patients_called(facility_2.region, :month,
        group_by: :called_by_user_id)).to eq(expected)
    end
  end
end
