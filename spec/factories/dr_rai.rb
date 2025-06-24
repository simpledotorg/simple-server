FactoryBot.define do
  factory :target, class: "DrRai::Target" do
    completed { false }
    period { "Q1-2021" }
    indicator { contact_overdue_patients_indicator }

    trait :numeric do
      type { "DrRai::NumericTarget" }
      numeric_value { 200 }
      numeric_units { "Units" }
    end

    trait :percentage do
      type { "DrRai::PercentageTarget" }
      numeric_value { 20 }
      numeric_units { "Percent" }
    end

    trait :boolean do
      type { "DrRai::BooleanTarget" }
    end
  end

  factory :indicator, class: "DrRai::Indicator" do
    trait :contact_overdue_patients do
      type { "DrRai::ContactOverduePatientsIndicator" }
    end
  end

  factory :action_plan, class: "DrRai::ActionPlan" do
    statement { "TODO" }
    actions do
      <<~TEXT
        This
        That
      TEXT
    end
    dr_rai_indicator { create(:indicator, :contact_overdue_patients) }
    dr_rai_target { create(:target, :percentage) }
    region
  end
end

def contact_overdue_patients_indicator
  indicator = DrRai::ContactOverduePatientsIndicator.first

  if indicator.nil?
    create(:indicator, :contact_overdue_patients)
  else
    indicator
  end
end
