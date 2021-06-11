class CreateReportingFacilities < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facilities, materialized: true
  end
end
