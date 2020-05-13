require 'rails_helper'

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) do
    create(:admin, :supervisor, facility_group: facility_group).tap do |user|
      user.user_permissions.create!(permission_slug: 'view_my_facilities')
    end
  end

  render_views

  before do
    sign_in(supervisor.email_authentication)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: {}

      expect(response).to be_successful
    end
  end

  describe 'GET #ranked_facilities' do
    it 'returns a success response' do
      get :ranked_facilities, params: {}

      expect(response).to be_successful
    end
  end

  describe 'GET #blood_pressure_control' do
    it 'returns a success response' do
      get :blood_pressure_control, params: {}

      expect(response).to be_successful
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

      expect(response).to be_successful
    end

    it 'instantiates a MyFacilities::RegistrationsQuery object with the right arguments and calls the required methods' do
      params = { period: :quarter }
      query_object = MyFacilities::RegistrationsQuery.new
      allow(MyFacilities::RegistrationsQuery).to receive(:new).with(hash_including(params.merge(last_n: 3)))
                                                   .and_return(query_object)

      expect(MyFacilities::RegistrationsQuery).to receive(:new)
                                                    .with(hash_including(facilities: facilities(Facility.where(id: facility_under_supervisor))))

      expect(query_object).to receive(:registrations).and_return(query_object.registrations)
      expect(query_object).to receive(:total_registrations).and_return(query_object.total_registrations)

      get :registrations, params: params
    end
  end

  describe 'GET #missed_visits' do
    let!(:facility_under_supervisor) { create(:facility, facility_group: facility_group) }
    let!(:facility_not_under_supervisor) { create(:facility) }
    let!(:patients) do
      [facility_under_supervisor, facility_not_under_supervisor].map do |facility|
        create(:patient, registration_facility: facility, recorded_at: 3.months.ago)
      end
    end

    it 'returns a success response' do
      get :missed_visits, params: {}

      expect(response).to be_successful
    end

    it 'instantiates a MyFacilities::MissedVisitsQuery object with the right arguments and calls the required methods' do
      params = { period: :quarter }
      query_object = MyFacilities::MissedVisitsQuery.new
      allow(MyFacilities::MissedVisitsQuery).to receive(:new).with(hash_including(params.merge(last_n: 3)))
                                                   .and_return(query_object)

      expect(MyFacilities::MissedVisitsQuery).to receive(:new)
                                                    .with(hash_including(facilities: facilities(Facility.where(id: facility_under_supervisor))))

      expect(query_object).to receive(:periods).and_return(query_object.periods)
      expect(query_object).to receive(:missed_visits_by_facility).and_return(query_object.missed_visits_by_facility).at_least(:once)
      expect(query_object).to receive(:missed_visit_totals).and_return(query_object.missed_visit_totals).at_least(:once)
      expect(query_object).to receive(:calls_made).and_return(query_object.calls_made)
      get :missed_visits, params: params
    end
  end
end
