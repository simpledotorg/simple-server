require 'rails_helper'
require 'yaml'

RSpec.describe 'refresh_materialized_db_views' do
  include RakeTestHelper

  let!(:refresh_begin_time) { Time.use_zone(Rails.application.config.country[:time_zone]) { Time.current } }
  let!(:matview_refresh_time_key) { Rails.application.config.app_constants[:MATVIEW_REFRESH_TIME_KEY] }

  before do
    Rails.cache.clear
  end

  it 'logs the time at which the refresh was completed in a cache store' do
    Timecop.freeze(refresh_begin_time) do
      invoke_task('refresh_materialized_db_views')
    end

    expect(Rails.cache.fetch(matview_refresh_time_key)).to eq(refresh_begin_time)
  end

  it 'does not modify the refresh time if any view fails to refresh' do
    Timecop.freeze(refresh_begin_time) do
      invoke_task('refresh_materialized_db_views')
    end

    Timecop.freeze(refresh_begin_time + 1.day) do
      allow(LatestBloodPressuresPerPatientPerDay).to receive(:refresh).and_raise(StandardError)

      expect {
        invoke_task('refresh_materialized_db_views')
      }.to raise_error(StandardError)
    end

    expect(Rails.cache.fetch(matview_refresh_time_key)).to eq(refresh_begin_time)
  end
end
