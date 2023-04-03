class PatientStates:: LostToFollowUpPatientsQueryDM
    attr_reader: region, :period
    
    def initialize(region,period)
        @region = region
        @period = period
    end

    def call 
        PatientStates::CumulativeAssignedPatientsQueryDM.new(region,period)
        .call
        .where (htn_care_state: "lost_to_follow_up")
    end
end




