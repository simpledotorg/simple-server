# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Time and Date formats" do
  let(:jan_1_date) { Date.parse("January 1st 2020") }
  let(:jan_1_time) { Time.parse("January 1st 2020 00:00:00") }

  it "has a mon year format for short month display" do
    expect(jan_1_date.to_s(:mon_year)).to eq("Jan-2020")
    expect(jan_1_time.to_s(:mon_year)).to eq("Jan-2020")
  end

  it "has month year format for full month display" do
    expect(jan_1_date.to_s(:month_year)).to eq("January 2020")
    expect(jan_1_time.to_s(:month_year)).to eq("January 2020")
  end

  it "has a multiline mon year format" do
    expect(jan_1_date.to_s(:mon_year_multiline)).to eq("Jan\n2020")
    expect(jan_1_time.to_s(:mon_year_multiline)).to eq("Jan\n2020")
  end
end
