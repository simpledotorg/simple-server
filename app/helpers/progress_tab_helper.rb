module ProgressTabHelper
  def create_badge_array(current_value)
    # Achievement badges are generated dynamically and follow the following infinite sequence where "S" is the starting badge value 
    # S x 2 x 2 x 2.5 x 2 x 2 x 2.5 x 2 x 2 x 2.5 ...
    # This will always return an array with 5 badges, where the last badge will always be incomplete
    # If the current_value is less than the fifth smallest goal (5,000 if starting_goal = 25), the function will return more than one incomplete badge
    goal_multipliers = [2, 2, 2.5]
    starting_goal = 25
    current_goal = starting_goal 
    multiplier_index = 0
    badges = []

    while current_value >= current_goal
      add_new_badge(current_goal, badges, true)
      update_current_goal(current_goal, multiplier_index, goal_multipliers)
      set_multiplier_index(multiplier_index, goal_multipliers)
    end

    if badges.length < 5
      (5 - badges.length).times {
        add_new_badge(current_goal, badges, false)
        update_current_goal(current_goal, multiplier_index, goal_multipliers)
        set_multiplier_index(multiplier_index, goal_multipliers)
      }
    else
      add_new_badge(current_goal, badges, false)
    end

    badges.last(5)
  end

  def update_current_goal(current_goal, multiplier_index, goal_multipliers)
    current_goal = (current_goal * goal_multipliers[multiplier_index]).to_i
  end

  def set_multiplier_index(multiplier_index, goal_multipliers)
    if multiplier_index == goal_multipliers.length - 1
      multiplier_index = 0
    else
      multiplier_index += 1
    end
  end

  def add_new_badge(current_goal, badges, is_goal_completed)
    badges.push({
      "goal_value" => current_goal.to_i,
      "is_goal_completed" => is_goal_completed
    })
  end
end
