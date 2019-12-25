require 'rails_helper'

RSpec.describe Api::Current::FacilitiesController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }

  let(:model) { Facility }

  def create_record_list(n, options = {})
    FactoryBot.create_list(:facility, n, facility_group: request_user.facility.facility_group)
  end

  describe 'a working Current sync controller sending records' do
    before :each do
      Timecop.travel(15.minutes.ago) do
        create_record_list(2)
      end
      Timecop.travel(14.minutes.ago) do
        create_record_list(2)
      end
    end

    describe 'GET sync: send data from server to device;' do
      let(:response_key) { model.to_s.underscore.pluralize }
      it 'Returns records from the beginning of time, when process_token is not set' do
        get :sync_to_user

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq model.count
        expect(response_body[response_key].map { |record| record['id'] }.to_set)
          .to eq(model.all.pluck(:id).to_set)
      end

      it 'only sends facilities that belong to a facility group' do
        facilities_without_group = FactoryBot.create_list(:facility, 2, facility_group: nil)
        get :sync_to_user

        response_body = JSON(response.body)
        expect(response_body[response_key].map { |record| record['id'] }.to_set)
          .not_to include(*facilities_without_group.map(&:id))
      end

      it 'Returns new records added since last sync' do
        expected_records = create_record_list(2, updated_at: 5.minutes.ago)
        get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: 10.minutes.ago }) }

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2

        expect(response_body[response_key].map { |record| record['id'] }.to_set)
          .to eq(expected_records.map(&:id).to_set)

        response_process_token = parse_process_token(response_body)
        expect(response_process_token[:other_facilities_processed_since].to_time.to_i)
          .to eq(expected_records.map(&:updated_at).max.to_i)
      end

      it 'Returns an empty list when there is nothing to sync' do
        sync_time = 10.minutes.ago
        get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: sync_time }) }
        response_body = JSON(response.body)
        response_process_token = parse_process_token(response_body)
        expect(response_body[response_key].count).to eq 0
        expect(response_process_token[:other_facilities_processed_since].to_time.to_i).to eq sync_time.to_i
      end

      # Skipping specs to due hotfix to return all facilities records in a single batch
      xdescribe 'batching' do
        it 'returns the number of records requested with limit' do
          get :sync_to_user, params: {
            process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
            limit: 2
          }
          response_body = JSON(response.body)
          expect(response_body[response_key].count).to eq 2
        end

        it 'Returns all the records on server over multiple small batches' do
          get :sync_to_user, params: {
            process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
            limit: 2
          }

          response_1 = JSON(response.body)

          get :sync_to_user, params: {
            process_token: response_1['process_token'],
            limit: 5
          }
          response_2 = JSON(response.body)

          received_records = response_1[response_key].concat(response_2[response_key]).to_set
          expect(received_records.count).to eq model.count

          expect(received_records.map { |record| record['id'] }.to_set)
            .to eq(model.all.pluck(:id).to_set)
        end
      end
    end
  end
end
