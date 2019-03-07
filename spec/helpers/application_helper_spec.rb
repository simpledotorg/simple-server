require 'rails_helper'

describe ApplicationHelper do
  context '#rounded_time_ago_in_words' do
    it 'should return Today if date is less than 24 hours' do
      date = Date.today
      expect(rounded_time_ago_in_words(date)).to eq("Today")
    end

    it 'should return Yesterday if date is from yesterday' do
      date = Date.yesterday
      expect(rounded_time_ago_in_words(date)).to eq("Yesterday")
    end

    it 'should return date in dd/mm/yyyy format if date is more than a year' do
      date = Date.parse('31-12-2016')
      expect(rounded_time_ago_in_words(date)).to eq("on 31/12/2016")
    end

    it 'should return date in number of ago if date is less than a year ago' do
      expect(rounded_time_ago_in_words(31.days.ago.to_date)).to eq("about 1 month ago")
      expect(rounded_time_ago_in_words(2.months.ago.to_date)).to eq("about 2 months ago")
      expect(rounded_time_ago_in_words(11.months.ago.to_date)).to eq("11 months ago")
    end
  end
end
