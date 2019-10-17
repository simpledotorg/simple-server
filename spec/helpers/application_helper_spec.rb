require 'rails_helper'

describe ApplicationHelper, type: :helper do
  context '#rounded_time_ago_in_words' do
    it 'should return Today if date is less than 24 hours' do
      date = Date.current
      expect(helper.rounded_time_ago_in_words(date)).to eq("Today")
    end

    it 'should return Yesterday if date is from yesterday' do
      date = Date.yesterday
      expect(helper.rounded_time_ago_in_words(date)).to eq("Yesterday")
    end

    it 'should return date in dd-MMM-yyyy format if date is more than a day ago' do
      date = Date.parse('31-12-2016')
      expect(helper.rounded_time_ago_in_words(date)).to eq("on 31-DEC-2016")
    end
  end

  describe '#handle_impossible_registration_date' do
    before :each do
      allow(ENV).to receive(:[]).with("PROGRAM_INCEPTION_DATE").and_return("2018-01-01")
    end

    it 'returns the formatted registraion data if it is greater than the program inception date' do
      expect(helper.handle_impossible_registration_date(Date.new(2019, 01, 01))).to eq('01-JAN-2019')
    end

    it "returns 'unclear' if the date is lesser than the program inception date" do
      expect(helper.handle_impossible_registration_date(Date.new(2017, 01, 01))).to eq('Unclear')
    end
  end

  describe '#show_last_interaction_date_and_result' do
    context 'When at least one previous visit exists' do
      it 'returns "Agreed to visit" if the last visit exists and has agreed_to_visit set' do
        patient = FactoryBot.create(:patient)
        appointment1 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment1.status = 'visited'
        appointment1.agreed_to_visit = true
        appointment1.remind_on = nil
        appointment1.save

        appointment2 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment2.scheduled_date = 60.days.from_now
        appointment2.save

        expect(show_last_interaction_date_and_result(patient)).to include('Agreed to visit')
      end

      it 'returns "Remind to call later" if the last visit exists and remind_on is not nil' do
        patient = FactoryBot.create(:patient)

        appointment1 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment1.status = 'visited'
        appointment1.agreed_to_visit = false
        appointment1.remind_on = Date.current
        appointment1.save

        appointment2 = FactoryBot.create(:appointment, :overdue, patient_id: patient.id)
        appointment2.scheduled_date = 60.days.from_now
        appointment2.save

        expect(show_last_interaction_date_and_result(patient)).to include('Remind to call later')
      end
    end
  end
end

