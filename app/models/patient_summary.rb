class PatientSummary < ActiveRecord::Base
  self.primary_key = :id

  def readonly?
    true
  end
end
