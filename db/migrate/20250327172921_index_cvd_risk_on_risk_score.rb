class IndexCvdRiskOnRiskScore < ActiveRecord::Migration[6.1]
  def change
    add_index :cvd_risks, :risk_score
  end
end
