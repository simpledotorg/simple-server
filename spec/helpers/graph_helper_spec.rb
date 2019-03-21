require 'rails_helper'

describe GraphHelper, type: :helper do
  describe '#column_height_styles' do
    it "returns the css styles for a column's height given value, max_value and height" do
      expect(helper.column_height_styles(1, max_value: 10, max_height: 100)).to eq('height: 10px;')
    end
  end
end