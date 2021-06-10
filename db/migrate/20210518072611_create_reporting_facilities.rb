class CreateReportingFacilities < ActiveRecord::Migration[5.2]
  def change
    # TODO: consider removing the materialized view here
    create_view :reporting_facilities, materialized: true
  end
end
