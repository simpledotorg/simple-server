require "rails_helper"

RSpec.describe RegionTreeService, type: :model do
  let!(:organization) { create(:organization, name: "my-org") }
  let!(:state) { create(:region, :state, reparent_to: organization.region) }
  let!(:facility_groups) { create_list(:facility_group, 2, state: state.name, organization: organization) }
  let!(:block_1) { create(:region, :block, name: "B1", reparent_to: facility_groups[0].region) }
  let!(:block_2) { create(:region, :block, name: "B2", reparent_to: facility_groups[1].region) }
  let!(:facility_1) { create(:facility, state: state.name, block: block_1.name, facility_group: facility_groups[0]) }

  class SQLCounter
    cattr_accessor :query_count do
      0
    end

    IGNORED_SQL = [/^PRAGMA (?!(table_info))/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /^SHOW max_identifier_length/]

    def call(name, start, finish, message_id, values)
      p name, values[:sql]
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      unless "CACHE" == values[:name]
        self.class.query_count += 1 unless IGNORED_SQL.any? { |r| values[:sql] =~ r }
      end
    end
  end

  before do
    ActiveSupport::Notifications.subscribe("sql.active_record", SQLCounter.new)
  end

  it "loads the same children as built in LTREE methods" do
    org_region = Organization.find(organization.id).region
    tree = described_class.new(org_region)

    expect(tree.fast_children(org_region)).to eq(org_region.children)
    expect(tree.fast_children(block_1)).to eq(block_1.children)
  end

  it "doesnt do AR queries" do
    org_region = Organization.find(organization.id).region
    tree = described_class.new(org_region)

    SQLCounter.query_count = 0

    tree.fast_children(org_region)
    expect(tree.fast_children(block_1).size).to be > 0
    expect(SQLCounter.query_count).to eq(0)
  end
end
