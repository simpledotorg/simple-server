require "rails_helper"

RSpec.describe VoiceAgentUser do
  let(:facility) { create(:facility) }
  let(:org_id) { facility.organization_id }

  it "creates a sync-denied bot user for the organization" do
    user = described_class.find_or_create(org_id: org_id)

    expect(user).to be_persisted
    expect(user.full_name).to eq("Simple Voice Agent")
    expect(user.organization_id).to eq(org_id)
    expect(user).to be_sync_approval_status_denied
  end

  it "returns the same user on subsequent calls" do
    expect(described_class.find_or_create(org_id: org_id)).to eq(described_class.find_or_create(org_id: org_id))
  end

  it "is a different user from the import bot user" do
    expect(described_class.find_or_create(org_id: org_id)).not_to eq(ImportUser.find_or_create(org_id: org_id))
  end
end
