class ChangeCvdRiskScoreToString < ActiveRecord::Migration[6.1]
  def change
    change_column(:cvd_risks, :risk_score, :string)
  end
end
