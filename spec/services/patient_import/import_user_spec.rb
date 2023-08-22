require "rails_helper"

RSpec.describe ImportUser do
  describe ".find" do
    it "finds existing import user by phone number" do
      import_user = create(:user, phone_number: ImportUser::IMPORT_USER_PHONE_NUMBER)

      expect(ImportUser.find).to eq(import_user)
    end

    it "returns nil if not found" do
      expect(ImportUser.find).to be_nil
    end
  end

  describe ".find_or_create" do
    it "finds existing import user by phone number" do
      import_user = create(:user, phone_number: ImportUser::IMPORT_USER_PHONE_NUMBER)

      expect { ImportUser.find_or_create }.not_to change { User.count }
      expect(ImportUser.find_or_create).to eq(import_user)
    end

    it "creates a new user if not found" do
      _facility = create(:facility)
      import_user = ImportUser.find_or_create
      expect(import_user).to be_persisted
      expect(import_user.phone_number).to eq(ImportUser::IMPORT_USER_PHONE_NUMBER)
    end

    it "ensures the new user cannot sync data" do
      _facility = create(:facility)
      import_user = ImportUser.find_or_create

      expect(import_user.otp_valid?).to eq(false)
      expect(import_user).to be_sync_approval_status_denied
    end
  end
end
