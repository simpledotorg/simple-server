class PatientStates:: ControlledPatientsQueryDM
  attr_reader: region:, :period

  def initialize(region,period)
    @region = region
    @period = period
  end

  def call
    PatientStates::CumulativeAssignedPatientsQueryDM.new(region, period)
     .call
     .where("months_since_registration >= ?", 3)
     .where(htn_care_state: "under_care", diabetes_treatment_outcome_in_last_3_months:("bs_below_200")
   )
   end
end


