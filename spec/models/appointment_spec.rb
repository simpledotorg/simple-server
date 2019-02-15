require 'rails_helper'

describe Appointment, type: :model do
  subject(:appointment) { build(:appointment) }

  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should have_many(:communications) }
  end

  context 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  context 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context 'Scopes' do
    describe '.overdue' do
      let(:overdue_appointment) { create(:appointment, :overdue) }
      let(:upcoming_appointment) { create(:appointment) }

      it "includes overdue appointments" do
        expect(Appointment.overdue).to include(overdue_appointment)
      end

      it "excludes non-overdue appointments" do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end
  end

  context "Virtual params" do
    describe ".call_result" do
      it "correctly records agreed to visit" do
        appointment.call_result = "agreed_to_visit"

        expect(appointment.agreed_to_visit).to eq(true)
        expect(appointment.cancel_reason).to be_nil
      end

      it "correctly records remind to call" do
        appointment.call_result = "remind_to_call_later"

        expect(appointment.agreed_to_visit).to be_nil
        expect(appointment.remind_on).to eq(7.days.from_now.to_date)
        expect(appointment.cancel_reason).to be_nil
      end

      Appointment.cancel_reasons.values.each do |cancel_reason|
        it "correctly records cancel reason: '#{cancel_reason}'" do
          appointment.call_result = cancel_reason

          expect(appointment.agreed_to_visit).to eq(false)
          expect(appointment.remind_on).to be_nil
          expect(appointment.cancel_reason).to eq(cancel_reason)
        end
      end
    end
  end
end
