require 'rails_helper'

describe GraphHelper, type: :helper do
  describe '#range_for_quarter' do
    let(:date) { Date.new(2019, 2, 1) }

    before :each do
      Timecop.travel(date)
    end

    after :each do
      Timecop.return
    end

    it 'returns the range for the current quarter given a zero offset' do
      expect(helper.range_for_quarter(0))
        .to eq(from_time: Date.new(2019, 1, 1), to_time: Date.new(2019, 3, 31))
    end

    it 'returns the range for a quarter given an positive offset' do
      expect(helper.range_for_quarter(1))
        .to eq(from_time: Date.new(2019, 4, 1), to_time: Date.new(2019, 6, 30))
    end

    it 'returns the range for a quarter given a negative offset' do
      expect(helper.range_for_quarter(-1))
        .to eq(from_time: Date.new(2018, 10, 1), to_time: Date.new(2018, 12, 31))
    end
  end

  describe '#label_for_quarter' do
    it 'returns the label for the quarter given a range' do
      expect(helper.label_for_quarter(from_time: Date.new(2019, 1, 1), to_time: Date.new(2019, 3, 31)))
        .to eq('Q1 2019')
    end

    it 'returns the label for the quarter given a range in the previous year' do
      expect(helper.label_for_quarter(from_time: Date.new(2018, 10, 1), to_time: Date.new(2018, 12, 31)))
        .to eq('Q4 2018')
    end
  end
end