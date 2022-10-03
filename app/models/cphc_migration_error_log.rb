class CphcMigrationErrorLog < ApplicationRecord
  belongs_to :cphc_migratable, polymorphic: true
  belongs_to :facility
end
