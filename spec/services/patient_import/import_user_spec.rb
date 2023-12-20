require "rails_helper"

RSpec.describe ImportUser do
  describe ".find" do
    it "finds existing import user by phone number" do
      org_id = build_stubbed(:organization).id
      import_user = create(:user, phone_number: ImportUser.bot_phone_number(org_id), organization_id: org_id)

      expect(ImportUser.find(org_id)).to eq(import_user)
    end

    it "returns nil if not found" do
      expect(ImportUser.find("foo")).to be_nil
    end

    it "returns nil if it does not exist in the given organization" do
      org_id = build_stubbed(:organization).id
      _user = create(:user, phone_number: ImportUser.bot_phone_number(org_id), organization_id: org_id)

      expect(ImportUser.find("bar")).to be_nil
    end
  end

  describe ".find_or_create" do
    it "finds existing import user by phone number" do
      org_id = build_stubbed(:organization).id
      import_user = create(:user, phone_number: ImportUser.bot_phone_number(org_id), organization_id: org_id)

      expect { ImportUser.find_or_create(org_id: org_id) }.not_to change { User.count }
      expect(ImportUser.find_or_create(org_id: org_id)).to eq(import_user)
    end

    it "creates a new user if not found" do
      facility = create(:facility)
      import_user = ImportUser.find_or_create(org_id: facility.organization_id)
      import_user_phone_number = ImportUser.bot_phone_number(facility.organization_id)

      expect(import_user).to be_persisted
      expect(import_user.phone_number).to eq(import_user_phone_number)
    end

    it "ensures the new user cannot sync data" do
      facility = create(:facility)
      import_user = ImportUser.find_or_create(org_id: facility.organization_id)

      expect(import_user.otp_valid?).to eq(false)
      expect(import_user).to be_sync_approval_status_denied
    end
  end

  describe "#bot_phone_number" do
    it "always gives the same output for an org ID" do
      some_org_id = SecureRandom.uuid

      expect(5.times.map { ImportUser.bot_phone_number(some_org_id) }.uniq.length).to eq(1)
    end
  end
end
