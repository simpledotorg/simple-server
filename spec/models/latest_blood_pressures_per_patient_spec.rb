# frozen_string_literal: true

require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatient, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:bp_facility) }
    it { is_expected.to belong_to(:registration_facility) }
  end
end
