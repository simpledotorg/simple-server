class CphcMigrationAuditLog < ApplicationRecord
  belongs_to :cphc_migratable, polymorphic: true
  validates :cphc_migratable_id, uniqueness: {scope: :cphc_migratable_type}
end
