# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::RegionTreeComponent, type: :component do
  def component
    @component ||= Reports::RegionTreeComponent.new(parent: instance_double(Region), children: {})
  end

  it "always returns true for accessible facility checks" do
    region = build(:region, region_type: "facility")
    expect(component.accessible_region?(region, :view_reports)).to be true
  end

  it "delegates to helper methods for other accessible checks" do
    block_region = build(:region, region_type: "block")
    fake_helpers = double("helpers")
    expect(fake_helpers).to receive(:accessible_region?).with(block_region, :view_reports).and_return(false)
    allow(component).to receive(:helpers).and_return(fake_helpers)
    expect(component.accessible_region?(block_region, :view_reports)).to be false
  end
end
