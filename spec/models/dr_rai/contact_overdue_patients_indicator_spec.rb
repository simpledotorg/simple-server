require "rails_helper"

RSpec.describe DrRai::ContactOverduePatientsIndicator, type: :model do
  describe "#is_supported?" do
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.new }

    context "when region has data" do
      before do
        allow(indicator).to receive(:datasource).with(region).and_return({"some" => "data"})
      end

      it "works" do
        expect(indicator.is_supported?(region)).to be_truthy
      end
    end

    context "when region has no data" do
      before do
        allow(indicator).to receive(:datasource).with(region).and_return({})
      end

      it "is unsupported" do
        expect(indicator.is_supported?(region)).to be_falsey
      end
    end
  end

  describe "indicator_function" do
    around do |example|
      Timecop.freeze("June 25 2025 15:12 GMT") { example.run }
    end

    let(:timezone) { Time.find_zone(Period::REPORTING_TIME_ZONE) }
    let(:this_month) { timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0) }
    let(:one_month_ago) { this_month - 1.month }
    let(:two_months_ago) { this_month - 2.month }
    let(:five_months_ago) { this_month - 5.month }
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:facility_1) { district_with_facilities[:facility_1] }
    let(:views) {
      %w[ Reports::Month
        Reports::Facility
        Reports::PatientVisit
        Reports::PatientState
        Reports::OverduePatient
        Reports::FacilityState].freeze
    }

    it "return the count of contactable patients called" do
      facility_1_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :hypertension, :removed_from_overdue_list, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_contactable_patients.each do |the_patient|
        create(:appointment, patient: the_patient, scheduled_date: one_month_ago, facility: facility_1, device_created_at: two_months_ago)
      end
      create(:call_result, patient: facility_1_contactable_patients.first, device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_contactable_patients.second, device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_contactable_patients.third, device_created_at: two_months_ago + 1.days)
      create(:call_result, patient: facility_1_patient_with_out_phone, device_created_at: this_month + 27.days)
      create(:call_result, patient: facility_1_patient_removed_from_list, device_created_at: this_month + 4.days)

      allow(Reports::PatientState).to receive(:get_refresh_months).and_return(ReportingHelpers.get_refresh_months_between_dates(5.months.ago.to_date, Date.today))
      RefreshReportingViews.new(views: views).call

      indicator = DrRai::ContactOverduePatientsIndicator.new

      period = Period.new(type: :quarter, value: this_month.to_period.to_quarter_period.value.to_s)
      facility_1_numerator = indicator.numerator(region, period, with_non_contactable: true)
      facility_1_denominator = indicator.denominator(region, period, with_non_contactable: true)

      expect(facility_1_numerator).to eq 6
      expect(facility_1_denominator).to eq 4
    end
  end
end
