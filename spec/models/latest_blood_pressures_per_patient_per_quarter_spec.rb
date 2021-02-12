require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerQuarter, type: :model do
  def refresh_views
    LatestBloodPressuresPerPatientPerMonth.refresh
    described_class.refresh
  end

  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "Scopes" do
    describe ".ltfu_as_of" do
      it "includes BP for patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(2.years.ago) { create(:blood_pressure, patient: ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current).pluck(:patient_id)).to include(ltfu_patient.id)
      end

      it "excludes BP for patient who is not LTFU" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end
    end

    describe ".not_ltfu_as_of" do
      it "excludes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(2.years.ago) { create(:blood_pressure, patient: ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).not_to include(ltfu_patient)
      end

      it "includes patient who is not LTFU" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current).pluck(:patient_id)).to include(not_ltfu_patient.id)
      end
    end
  end
end
