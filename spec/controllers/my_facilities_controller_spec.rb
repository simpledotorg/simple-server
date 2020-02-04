require 'rails_helper'

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) { create(:admin, :supervisor, facility_group: facility_group) }

  render_views

  before do
    sign_in(supervisor.email_authentication)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: {}

      expect(response).to be_success
    end
  end

  describe 'GET #ranked_facilities' do
    it 'returns a success response' do
      get :ranked_facilities, params: {}

      expect(response).to be_success
    end
  end

  describe 'GET #blood_pressure_control' do
    it 'returns a success response' do
      get :blood_pressure_control, params: {}

      expect(response).to be_success
    end
  end

  describe 'GET #registrations' do
    let!(:facility_under_supervisor) { create(:facility, facility_group: facility_group) }
    let!(:facility_not_under_supervisor) { create(:facility) }
    let!(:patients) do
      [facility_under_supervisor, facility_not_under_supervisor].map do |facility|
        create(:patient, registration_facility: facility, recorded_at: 3.months.ago)
      end
    end

    it 'returns a success response' do
      get :registrations, params: {}

      expect(response).to be_success
    end

    it 'instantiates a MyFacilities::RegistrationsQuery object with the right arguments and calls the required methods' do
      params = { period: :quarter }
      query_object = MyFacilities::RegistrationsQuery.new
      allow(MyFacilities::RegistrationsQuery).to receive(:new).with(hash_including(params))
      allow(MyFacilities::RegistrationsQuery).to receive(:new)
                                                     .with(hash_including(include_quarters: 3, include_months: 3, include_days: 14))
                                                     .and_return(query_object)
      allow(MyFacilities::RegistrationsQuery).to receive(:new)
                                                     .with(hash_including(facilities(Facility.where(id: facility_under_supervisor))))
                                                     .and_return(query_object)

      expect(query_object).to receive(:registrations).and_return(query_object.registrations)
      expect(query_object).to receive(:all_time_registrations).and_return(query_object.all_time_registrations)

      get :registrations, params: params
    end
  end
end
