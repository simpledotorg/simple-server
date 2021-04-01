class CreateEncountersOverTime < ActiveRecord::Migration[5.2]
  def change
    create_view :encounters_over_time, materialized: true
  end
end
