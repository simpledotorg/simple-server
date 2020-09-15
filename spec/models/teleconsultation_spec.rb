require "rails_helper"

RSpec.describe Teleconsultation, type: :model do
  it { should belong_to(:patient) }
  it { should belong_to(:medical_officer).class_name("User") }
  it { should belong_to(:requester).class_name("User").optional }
  it { should belong_to(:facility).optional }
end
