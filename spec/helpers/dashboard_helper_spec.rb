require 'rails_helper'

RSpec.describe DashboardHelper, type: :helper do
  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }
  let(:first_apr) { Date.new(2019, 4, 1) }

  describe '#repeat_for_last' do
    it 'should yield the contents repeatedly for last n months' do
      contents = []

      Timecop.travel(first_apr) do
        repeat_for_last(months: 4) { |month| contents << month }
      end

      expect(contents).to eq([first_jan, first_feb, first_mar, first_apr])
    end
  end
end
