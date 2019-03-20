require 'rails_helper'

describe GraphHelper, type: :helper do
  describe '#column_height_styles' do
    it "returns the css styles for a column's height given value, max_value and height" do
      expect(helper.column_height_styles(1, max_value: 10, max_height: 100)).to eq('height: 10px;')
    end
  end

  describe '#week_label' do
    it 'returns the label for a column give the from date and to date' do
      from_date_string = '2019-1-1'
      to_date_string = '2019-3-31'
      expected_label = content_tag('div', class: 'graph-label') do
        concat(content_tag('div', from_date_string, class: 'label-1'))
        concat(content_tag('div', to_date_string, class: 'label-1'))
      end

      expect(helper.week_label(from_date_string, to_date_string))
        .to eq(expected_label)
    end
  end
end