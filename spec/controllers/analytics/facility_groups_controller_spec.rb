require 'rails_helper'

RSpec.describe Analytics::FacilityGroupsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }

  let(:facility_group) { create(:facility_group) }

  before do
    sign_in(admin)
  end

  describe '#show' do
    it 'returns 400 if from_time and to_time are missing' do
      get :show, params: { id: facility_group.id }

      expect(response.status).to eq(400)
    end

    context 'from_time and to_time are set' do
      render_views

      it 'render the facility analytics table for the facilities in the group' do
        get :show, params: { id: facility_group.id, from_time: from_time, to_time: to_time }

        expect(response).to render_template(partial: '_facility_table')
      end

      it 'has summary for all the facilties in the facility group' do
        facilities = create_list :facility, 3, facility_group: facility_group

        get :show, params: { id: facility_group.id, from_time: from_time, to_time: to_time }

        facilities.each do |facility|
          expect(response.body).to match(Regexp.new(facility.name))
        end
      end
    end
  end
end
