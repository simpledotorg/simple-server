module ProgressTabHelper
  GOAL_MULTIPLIERS = [2, 2, 2.5]
  STARTING_GOAL = 25
  TOTAL_BADGES = 5

  def create_badge_array(current_value)
    # Achievement badges are generated dynamically and follow the following infinite sequence where "S" is the starting badge value
    # S x 2 x 2 x 2.5 x 2 x 2 x 2.5 x 2 x 2 x 2.5 ...
    current_goal = 25
    multiplier_index = 0
    badges = []

    while current_value && (current_value >= current_goal)
      add_badges_to_array(current_goal, true, badges)
      current_goal = set_current_goal(current_goal, multiplier_index)
      multiplier_index = set_multiplier_index(multiplier_index)
    end

    if badges.length < TOTAL_BADGES
      (TOTAL_BADGES - badges.length).times {
        add_badges_to_array(current_goal, false, badges)
        current_goal = set_current_goal(current_goal, multiplier_index)
        multiplier_index = set_multiplier_index(multiplier_index)
      }
    else
      add_badges_to_array(current_goal, false, badges)
    end

    badges.last(TOTAL_BADGES)
  end

  def add_badges_to_array(current_goal, is_goal_completed, badge_array)
    badge_array.push({
      "goal_value" => current_goal,
      "is_goal_completed" => is_goal_completed
    })
  end

  def set_current_goal(current_goal, multiplier_index)
    (current_goal * GOAL_MULTIPLIERS[multiplier_index]).to_i
  end

  def set_multiplier_index(multiplier_index)
    if multiplier_index == GOAL_MULTIPLIERS.length - 1
      0
    else
      multiplier_index + 1
    end
  end
end
