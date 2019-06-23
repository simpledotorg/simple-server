require 'rails_helper'

RSpec.describe Analytics::DistrictsController, type: :controller do
  let(:admin) { create(:user, :with_email_authentication) }
  let(:from_time) { Time.new(2019, 1, 1) }
  let(:to_time) { Time.new(2019, 3, 31) }

  let(:district_name) { 'Bathinda' }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facility) { create(:facility, facility_group: facility_group, district: district_name) }
  let(:organization_district) { OrganizationDistrict.new(district_name, organization) }
  let!(:patients) do
    patient_ids = create_list(:patient, 5, registration_facility: facility).map(&:id)
    Patient.where(id: patient_ids)
  end
  before do
    sign_in(admin.email_authentication)
  end

  describe '#show' do
    it 'returns 400 if from_time and to_time are missing' do
      get :show, params: { organization_id: organization.id, id: district_name }

      expect(response.status).to eq(400)
    end

    context 'organization district analytics are cached' do
      before :each do
        organization_district.patient_set_analytics(from_time, to_time)
      end

      it 'fetches the analytics from the rails cache to render the page' do
        expect(Rails.cache).to receive(:fetch).with(facility.analytics_cache_key(from_time, to_time))
        expect(Rails.cache).to receive(:fetch).with(organization_district.analytics_cache_key(from_time, to_time))
        expect(Analytics::PatientSetAnalytics).not_to receive(:new)

        get :show, params: { organization_id: organization.id, id: district_name, from_time: from_time, to_time: to_time }
      end
    end

    context 'organization district analytics are not cached' do
      before :each do
        Rails.cache.clear
      end

      it 'stores the calculated analytics in the cache' do
        expect(Rails.cache.exist?(organization_district.analytics_cache_key(from_time, to_time))).to be_falsey

        get :show, params: { organization_id: organization.id,
                             id: district_name,
                             from_time: from_time,
                             to_time: to_time }

        expect(Rails.cache.exist?(organization_district.analytics_cache_key(from_time, to_time))).to be_truthy
      end

      it 'calculates the patient set analytics for all the patients in the district' do
        request_time = Time.new(2019, 6, 1)

        Timecop.freeze(request_time) do
          get :show, params: { organization_id: organization.id,
                               id: district_name,
                               from_time: from_time,
                               to_time: to_time }
        end

        expected_analytics_keys = [:newly_enrolled_patients,
                                   :returning_patients,
                                   :non_returning_hypertensive_patients,
                                   :control_rate,
                                   :unique_patients_enrolled,
                                   :blood_pressures_recorded_per_week,
                                   :cache_updated_at]

        expect(assigns(:district_analytics).keys).to match_array(expected_analytics_keys)
        expect(assigns(:district_analytics)[:cache_updated_at]).to eq(request_time)
        expect(assigns(:facility_analytics)[facility].keys).to match_array(expected_analytics_keys)
      end
    end
  end
end
