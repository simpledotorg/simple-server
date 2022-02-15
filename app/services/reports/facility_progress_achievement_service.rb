module Reports
  class FacilityProgressAchievementService
    TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
    TROPHY_MILESTONE_INCR = 10_000

    attr_reader :facility

    def initialize(facility)
      @facility = facility
    end

    def statistics
      @statistics ||= {trophies: trophy_stats}
    end

    def total_counts
      @total_counts ||= Reports::FacilityStateDimension.totals(facility)
    end

    def trophy_stats
      follow_up_count = total_counts.monthly_follow_ups_htn_all || 0
      milestones = trophy_milestones(follow_up_count)
      locked_milestone_idx = milestones.index { |milestone| follow_up_count < milestone }

      {
        locked_trophy_value:
          milestones[locked_milestone_idx],

        unlocked_trophy_values:
          milestones[0, locked_milestone_idx]
      }
    end

    #
    # After exhausting the initial TROPHY_MILESTONES, subsequent milestones must follow the following pattern:
    #
    # 10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000, 10_000, 20_000, 30_000, etc.
    #
    # i.e. increment by TROPHY_MILESTONE_INCR
    def trophy_milestones(follow_up_count)
      if follow_up_count >= TROPHY_MILESTONES.last
        [*TROPHY_MILESTONES,
          *(TROPHY_MILESTONE_INCR..(follow_up_count + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)]
      else
        TROPHY_MILESTONES
      end
    end
  end
end
