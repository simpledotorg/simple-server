class ChangeTeleconsultationRequestCompleted < ActiveRecord::Migration[5.2]
  def change
    rename_column :teleconsultations, :request_completed, :requester_completion_status
  end
end
