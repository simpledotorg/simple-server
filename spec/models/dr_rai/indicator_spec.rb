require 'rails_helper'

RSpec.describe DrRai::Indicator, type: :model do
  describe 'validations:' do
    it 'title must be present' do
      new_target = DrRai::Indicator.new
      expect(new_target).not_to be_valid
      expect(new_target.errors.added?(:title, :blank)).to be_truthy
    end
  end
end
