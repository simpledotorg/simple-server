require 'rails_helper'

RSpec.describe Analytics::FacilitiesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let(:district_name) { 'Bathinda' }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility) { create(:facility, facility_group: facility_group, district: district_name) }

  before do
    #
    # register patients
    #
    registered_patients = Timecop.travel(Date.new(2019, 1, 1)) do
      create_list(:patient, 3, registration_facility: facility, registration_user: user)
    end

    #
    # add blood_pressures next month
    #
    Timecop.travel(Date.new(2019, 2, 1)) do
      registered_patients.each { |patient| create(:blood_pressure,
                                                  patient: patient,
                                                  facility: facility,
                                                  user: user) }
    end

    Patient.where(id: registered_patients.map(&:id))
  end

  before do
    sign_in(admin)
  end

  describe '#show' do
    render_views

    it 'returns relevant analytics keys per facility' do
      get :show, params: { id: facility.id }

      expect(response.status).to eq(200)
      expect(assigns(:analytics)[user.id].keys).to eq([:follow_up_patients_by_month,
                                                       :registered_patients_by_month,
                                                       :total_registered_patients])
    end

    it 'renders the analytics table view' do
      get :show, params: { id: facility.id }
      expect(response).to render_template(partial: 'shared/_analytics_table')
    end
  end
end
