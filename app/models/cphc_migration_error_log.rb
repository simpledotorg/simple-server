class CphcMigrationAuditLog < ApplicationRecord
  belongs_to :cphc_migratable, polymorphic: true
end
