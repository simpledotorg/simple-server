module ProgressTabHelper
  def create_badge_array(current_value)
    # Badge goals: 25, 50, 100, 250, 500, 1000, 2500...
    goal_multipliers = [2, 2, 2.5]
    starting_goal = 25
    current_goal = starting_goal
    multiplier_index = 0

    badges = []

    while current_value > current_goal
      badges.push({
        "goal_value" => current_goal,
        "is_goal_completed" => true
      })

      current_goal = (current_goal * goal_multipliers[multiplier_index]).to_i
      if multiplier_index == goal_multipliers.length - 1
        multiplier_index = 0
      else
        multiplier_index += 1
      end
    end

    badges.push({
      "goal_value" => current_goal.to_i,
      "is_goal_completed" => false
    })

    badges.reverse
  end
end
