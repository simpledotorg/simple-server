class RecreateViewReportingPatientStates < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      CREATE OR REPLACE VIEW public.reporting_patient_states AS SELECT * FROM simple_reporting.reporting_patient_states;
    SQL
  end
end
