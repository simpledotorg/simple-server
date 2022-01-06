# frozen_string_literal: true

require "rails_helper"

describe GraphHelper, type: :helper do
  describe "#column_height_styles" do
    it "returns the css styles for a column's height given value, max_value and height" do
      expect(helper.column_height_styles(1, max_value: 10, max_height: 100)).to eq("height: 10px;")
    end
  end

  describe "#latest_months" do
    let(:number_of_months) { 4 }
    let(:graph_data) { (1..6).map { |n| [Date.new(2019, n, 1), 0] }.to_h }

    it "selects the latest n months from the provided graph data" do
      expect(helper.latest_months(graph_data, number_of_months))
        .to eq("Jun" => 0,
          "May" => 0,
          "Apr" => 0,
          "Mar" => 0)
    end
  end
end
