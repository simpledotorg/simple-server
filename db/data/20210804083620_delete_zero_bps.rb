class DeleteZeroBps < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current[:abbreviation] == "ET"

    zero_bps = BloodPressure.where(systolic: 0, diastolic: 0)

    zero_bps.find_each do |blood_pressure|
      blood_pressure.observation&.discard
      blood_pressure.discard
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
