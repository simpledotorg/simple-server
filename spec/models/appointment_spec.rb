require 'rails_helper'

describe Appointment, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end
end
