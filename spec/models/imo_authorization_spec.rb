# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImoAuthorization, type: :model do
  describe "associations" do
    it { should belong_to(:patient) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:last_invited_at) }
  end
end
