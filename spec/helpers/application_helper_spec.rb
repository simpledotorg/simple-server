require 'rails_helper'

describe ApplicationHelper, type: :helper do
  context '#rounded_time_ago_in_words' do
    it 'should return Today if date is less than 24 hours' do
      date = Date.today
      expect(helper.rounded_time_ago_in_words(date)).to eq("Today")
    end

    it 'should return Yesterday if date is from yesterday' do
      date = Date.yesterday
      expect(helper.rounded_time_ago_in_words(date)).to eq("Yesterday")
    end

    it 'should return date in dd/mm/yyyy format if date is more than a year' do
      date = Date.parse('31-12-2016')
      expect(helper.rounded_time_ago_in_words(date)).to eq("on 31/12/2016")
    end

    it 'should return date in number of ago if date is less than a year ago' do
      expect(helper.rounded_time_ago_in_words(31.days.ago.to_date)).to eq("about 1 month ago")
      expect(helper.rounded_time_ago_in_words(2.months.ago.to_date)).to eq("about 2 months ago")
      expect(helper.rounded_time_ago_in_words(11.months.ago.to_date)).to eq("11 months ago")
    end
  end

  describe '#handle_impossible_registration_date' do
    before :each do
      allow(ENV).to receive(:[]).with("PROGRAM_INCEPTION_DATE").and_return("2018-01-01")
    end

    it 'returns the formatted registraion data if it is greater than the program inception date' do
      expect(helper.handle_impossible_registration_date(Date.new(2019, 01, 01))).to eq('01-Jan-2019')
    end

    it "returns 'unclear' if the date is lesser than the program inception date" do
      expect(helper.handle_impossible_registration_date(Date.new(2017, 01, 01))).to eq('unclear')
    end
  end
end
