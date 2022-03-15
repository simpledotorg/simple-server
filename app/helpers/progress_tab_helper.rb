module ProgressTabHelper
  def create_badge_array(current_value)
    # Achievement badges are generated dynamically and follow the following infinite sequence where "S" is the starting badge value 
    # S x 2 x 2 x 2.5 x 2 x 2 x 2.5 x 2 x 2 x 2.5 ...
    goal_multipliers = [2, 2, 2.5]
    starting_goal = 25
    current_goal = starting_goal 
    multiplier_index = 0

    badges = []

    while current_value >= current_goal
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

    if badges.length < 5
      (5 - badges.length).times {
        badges.push({
          "goal_value" => current_goal.to_i,
          "is_goal_completed" => false
        })

        current_goal = (current_goal * goal_multipliers[multiplier_index]).to_i
        if multiplier_index == goal_multipliers.length - 1
          multiplier_index = 0
        else
          multiplier_index += 1
        end
      }
    else
      badges.push({
        "goal_value" => current_goal.to_i,
        "is_goal_completed" => false
      })
    end

    badges.last(5)
  end
end
