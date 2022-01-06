# frozen_string_literal: true

require "rails_helper"

describe DrugStock, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:facility).optional }
    it { should belong_to(:protocol_drug) }
  end

  describe "Validations" do
    it { should validate_presence_of(:for_end_of_month) }
    it { should validate_numericality_of(:in_stock) }
    it { should validate_numericality_of(:received) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Returns latest records for a given facility and month" do
    let(:facility_group) { create(:facility_group) }
    let(:protocol_drug) { create(:protocol_drug, stock_tracked: true, protocol: facility_group.protocol) }
    let(:protocol_drug_2) { create(:protocol_drug, stock_tracked: true, protocol: facility_group.protocol) }
    let(:facility) { create(:facility, facility_group: facility_group) }

    it "returns latest stocks for end of jan" do
      end_of_january = Date.strptime("Jan-2021", "%b-%Y").end_of_month
      _jan_drug_1_stock_1 = create(:drug_stock,
        facility: facility,
        protocol_drug: protocol_drug,
        for_end_of_month: end_of_january,
        created_at: 25.minute.ago)
      jan_drug_1_stock_2 = create(:drug_stock,
        facility: facility,
        protocol_drug: protocol_drug,
        for_end_of_month: end_of_january,
        created_at: 5.minute.ago)
      _jan_drug_2_stock_1 = create(:drug_stock,
        facility: facility,
        protocol_drug: protocol_drug_2,
        for_end_of_month: end_of_january,
        created_at: 25.minute.ago)
      jan_drug_2_stock_2 = create(:drug_stock,
        facility: facility,
        protocol_drug: protocol_drug_2,
        for_end_of_month: end_of_january,
        created_at: 5.minute.ago)

      latest_drug_stocks = DrugStock.latest_for_facilities([facility], end_of_january).to_a
      expect(latest_drug_stocks).to include(jan_drug_1_stock_2, jan_drug_2_stock_2)
    end
  end
end
