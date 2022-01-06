# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientDeduplication::Runner do
  describe "#perform" do
    it "handles errors and reports them" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      allow_any_instance_of(PatientDeduplication::Deduplicator).to receive(:errors).and_return(["Some error"])

      instance = described_class.new(PatientDeduplication::Strategies.identifier_and_full_name_match)
      instance.call
      expect(instance.merge_failures).to eq [["Some error"]]
    end

    it "reports success and failures" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      instance = described_class.new(PatientDeduplication::Strategies.identifier_and_full_name_match)
      instance.call
      expect(instance.report_stats).to eq({processed: {total: 2,
                                                       distinct: 1},
                                           merged: {total: 2,
                                                    distinct: 1,
                                                    total_failures: 0,
                                                    distinct_failures: 0}})
    end
  end
end
