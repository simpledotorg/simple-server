require "rails_helper"

describe PatientAttribute, type: :model do
  describe "Associations" do
    it { should belong_to(:patient).optional }
  end

  it_behaves_like "a syncable model"
end
