require 'rails_helper'

RSpec.describe Analytics::FacilitiesController, type: :controller do
  let(:admin) { create(:admin) }
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }

  let(:facility) { create(:facility) }

  before do
    sign_in(admin)
  end

  describe '#show' do
    it 'returns 400 if from_time and to_time are missing' do
      get :show, params: { id: facility.id }

      expect(response.status).to eq(400)
    end

    context 'from_time and to_time are set' do
      render_views

      it 'has summary for all the users that have recorded blood pressures in the facility' do
        users = create_list :user, 3
        users.each do |user|
          create :blood_pressure, user: user, facility: facility
        end

        get :show, params: { id: facility.id, from_time: from_time, to_time: to_time }

        users.each do |user|
          expect(response.body).to match(Regexp.new(user.full_name))
        end
      end
    end
  end
end
