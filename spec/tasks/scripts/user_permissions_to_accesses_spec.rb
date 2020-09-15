require "rails_helper"
require "tasks/scripts/create_accesses_from_permissions"

RSpec.describe CreateAccessesFromPermissions do
  describe ".do" do
    let!(:ihci) { create(:organization, name: "IHCI") }
    let!(:facility_group) { create(:facility_group, organization: ihci) }
    let!(:facility) { create(:facility, facility_group: facility_group) }

    context "access_level" do
      CreateAccessesFromPermissions::OLD_ACCESS_LEVELS_TO_NEW.each do |old_access_level, new_access_level|
        it "makes #{old_access_level} -> #{new_access_level}" do
          user = create(:admin, old_access_level, access_level: nil, organization: ihci)

          CreateAccessesFromPermissions.do(verbose: false)
          user.reload

          expect(user.access_level).to eq(new_access_level)
        end
      end
    end

    context "accesses" do
      [:supervisor, :sts, :counsellor, :analyst].each do |access_level|
        it "creates facility_group accesses for #{access_level}" do
          user = create(:admin, access_level, access_level: nil, organization: ihci, facility_group: facility_group)

          CreateAccessesFromPermissions.do(verbose: false)
          user.reload

          expect(user.accesses.map(&:resource)).to match_array(facility_group)
        end
      end

      [:organization_owner].each do |access_level|
        it "creates organization accesses for #{access_level}" do
          user = create(:admin, access_level, access_level: nil, organization: ihci)

          CreateAccessesFromPermissions.do(verbose: false)
          user.reload

          expect(user.accesses.map(&:resource)).to match_array(ihci)
        end
      end

      it "creates no accesses for owners" do
        user = create(:admin, :owner, access_level: nil, organization: ihci)

        CreateAccessesFromPermissions.do(verbose: false)
        user.reload

        expect(user.accesses.map(&:resource)).to be_empty
      end
    end
  end
end
