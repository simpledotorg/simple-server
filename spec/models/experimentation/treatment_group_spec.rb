# frozen_string_literal: true

require "rails_helper"

RSpec.describe Experimentation::TreatmentGroup, type: :model do
  describe "associations" do
    it { should belong_to(:experiment) }
    it { should have_many(:reminder_templates) }
    it { should have_many(:treatment_group_memberships) }
    it { should have_many(:patients).through(:treatment_group_memberships) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
  end
end
