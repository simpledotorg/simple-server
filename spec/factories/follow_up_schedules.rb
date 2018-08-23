FactoryBot.define do
  factory :follow_up_schedule do
    id { SecureRandom.uuid }
    facility
    association :patient, strategy: :build
    next_visit { 30.days.from_now }
    action_by_user_id { FactoryBot.create(:user).id }
    user_action { :scheduled }
    reason_for_action { :already_visited }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_follow_up_schedule_payload(follow_up_schedule = FactoryBot.build(:follow_up_schedule))
  follow_up_schedule.attributes.with_payload_keys
end

def build_invalid_follow_up_schedule_payload
  build_follow_up_schedule_payload.merge(
    'user_action' => nil,
    'next_visit' => 'foo'
  )
end

def updated_follow_up_schedule_payload(existing_follow_up_schedule)
  update_time = 10.days.from_now
  updated_user_action = FollowUpSchedule.user_actions.keys
                          .reject { |action| action == existing_follow_up_schedule.user_action.to_s}
                          .sample

  build_follow_up_schedule_payload(existing_follow_up_schedule).merge(
    'updated_at' => update_time,
    'user_action' => updated_user_action
  )
end