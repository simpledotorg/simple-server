# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportFacilitiesJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform_later" do
    let(:organization) { create(:organization, name: "OrgOne") }
    let(:facility_group) { create(:facility_group, name: "FGTwo", organization_id: organization.id) }
    let(:block) { create(:region, :block, name: "Block1", reparent_to: facility_group.region) }
    let(:facilities) do
      [
        attributes_for(:facility, block: block.name, organization_name: organization.name,
                                  facility_group_name: facility_group.name, district: facility_group, state: "nirvana").except(:id),
        attributes_for(:facility, block: block.name, organization_name: organization.name,
                                  facility_group_name: facility_group.name, district: facility_group, state: "nirvana").except(:id)
      ]
    end
    let(:job) { ImportFacilitiesJob.perform_later(facilities) }

    it "queues the job" do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it "queues the job on the default queue" do
      expect(job.queue_name).to eq("default")
    end

    it "imports the specified facilities" do
      expect {
        perform_enqueued_jobs { job }
      }.to change(Facility, :count).by(2)
    end

    context "regions" do
      before { facilities }

      it "creates regions after importing facilities" do
        expect {
          perform_enqueued_jobs { job }
        }.to change(Region.facility_regions, :count).by(2)
      end

      it "does not import facilities if creating regions fails" do
        allow_any_instance_of(Facility).to receive(:make_region).and_raise(ActiveRecord::RecordInvalid)

        expect {
          perform_enqueued_jobs { job }
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Facility.count).to eq(0)
      end
    end
  end
end
