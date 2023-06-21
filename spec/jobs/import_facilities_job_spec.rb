require "rails_helper"

RSpec.describe ImportFacilitiesJob do
  include ActiveJob::TestHelper

  describe "#perform_later" do
    let(:organization) { create(:organization, name: "OrgOne") }
    let(:facility_group) { create(:facility_group, name: "FGTwo", organization_id: organization.id) }
    let(:block) { create(:region, :block, name: "Block1", reparent_to: facility_group.region) }
    let(:facility_1) do
      attributes_for(:facility, block: block.name, organization_name: organization.name,
                     facility_group_name: facility_group.name, district: facility_group, state: "nirvana")
    end
    let(:facility_2) do
      attributes_for(:facility, block: block.name, organization_name: organization.name,
                     facility_group_name: facility_group.name, district: facility_group, state: "nirvana")
    end
    let(:parsed_facilities) do
      [
        {
          facility: facility_1,
          business_identifiers: [
            attributes_for(:facility_business_identifier, facility_id: facility_1[:id],
                           identifier: "FBI", identifier_type: :external_org_facility_id).except(:id)
          ]
        },
        {facility: facility_2, business_identifiers: []}
      ]
    end
    let(:job) { ImportFacilitiesJob.perform_later(parsed_facilities) }

    it "queues the job" do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it "queues the job on the default queue" do
      expect(job.queue_name).to eq("default")
    end

    it "imports the specified facilities and business identifiers" do
      expect {
        perform_enqueued_jobs { job }
      }.to change(Facility, :count).by(2)
        .and change(FacilityBusinessIdentifier, :count).by(1)
    end

    it "does not import facilities if business identifiers are invalid" do
      _invalid_job = ImportFacilitiesJob.perform_later([
        {
          facility: facility_1.merge(id: SecureRandom.uuid),
          business_identifiers: [
            attributes_for(:facility_business_identifier, facility_id: "invalid").except(:id)
          ]
        },
        {
          facility: facility_2.merge(id: SecureRandom.uuid), business_identifiers: []
        }
      ])

      expect {
        perform_enqueued_jobs
      }.to raise_error(ActiveRecord::RecordInvalid)
        .and change(Facility, :count).by(0)
        .and change(FacilityBusinessIdentifier, :count).by(0)
    end

    context "regions" do
      it "creates regions after importing facilities" do
        expect {
          perform_enqueued_jobs { job }
        }.to change(Region.facility_regions, :count).by(2)
      end

      it "does not import facilities if creating regions fails" do
        allow_any_instance_of(Facility).to receive(:make_region).and_raise(ActiveRecord::RecordInvalid)

        expect {
          job
          perform_enqueued_jobs
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Facility.count).to eq(0)
      end
    end
  end
end
