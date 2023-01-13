def group(item: [])
  { type: "group",
    view_type: "view_group",
    display_properties: {
      orientation: "vertical"
    },
    item: item
  }
end

def horizontal_group(item: [])
  { type: "group",
    view_type: "view_group",
    display_properties: {
      orientation: "horizontal"
    },
    item: item
  }
end

def sub_header(text)
  {
    text: text,
    type: "display",
    view_type: "sub_header"
  }
end

def header(text)
  {
    text: text,
    type: "display",
    view_type: "header"
  }
end

def separator
  {
    type: "display",
    view_type: "separator"
  }
end

def line_separator
  {
    type: "display",
    view_type: "line_separator"
  }
end

def input(text, link_id, min: 0, max: 100_000)
  {
    link_id: link_id || text.split("monthly_screening_reports.")[1..],
    text: text,
    type: "integer",
    view_type: "input_field",
    validations: {
      min: min,
      max: max
    }
  }
end

def q
  group(item: [
    sub_header("monthly_screening_reports.monthly_opd_visits_gt_30"),
    input("monthly_screening_reports.outpatient_department_visits", "outpatient_department_visits"),
    separator,
    header("monthly_screening_reports.htn_and_dm_screening"),
    sub_header("monthly_screening_reports.total_bp_checks"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male", "total_bp_checks.male"),
        input("monthly_screening_reports.female", "total_bp_checks.female"),
      ]
    ),
    sub_header("monthly_screening_reports.total_blood_sugar_checks"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "total_blood_sugar_checks.male"),
        input("monthly_screening_reports.female",
              "total_blood_sugar_checks.female"),
      ]
    ),
    separator,
    header("monthly_screening_reports.new_suspected_individuals"),
    sub_header("monthly_screening_reports.new_suspected_individuals_htn"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "new_suspected_individuals_htn.male"),
        input("monthly_screening_reports.female",
              "new_suspected_individuals_htn.female"),
      ]
    ),
    sub_header("monthly_screening_reports.new_suspected_individuals_dm"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "new_suspected_individuals_dm.male"),
        input("monthly_screening_reports.female",
              "new_suspected_individuals_dm.female"),
      ]
    ),
    sub_header("monthly_screening_reports.new_suspected_individuals_htn_and_dm"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "new_suspected_individuals_htn_and_dm.male"),
        input("monthly_screening_reports.female",
              "new_suspected_individuals_htn_and_dm.female"),
      ]
    ),
    separator,
    header("monthly_screening_reports.diagnosed_cases_on_follow_up"),
    sub_header("monthly_screening_reports.diagnosed_cases_on_follow_up_htn"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "diagnosed_cases_on_follow_up_htn.male"),
        input("monthly_screening_reports.female",
              "diagnosed_cases_on_follow_up_htn.female"),
      ]
    ),
    sub_header("monthly_screening_reports.diagnosed_cases_on_follow_up_dm"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "diagnosed_cases_on_follow_up_dm.male"),
        input("monthly_screening_reports.female",
              "diagnosed_cases_on_follow_up_dm.female"),
      ]
    ),
    sub_header("monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "diagnosed_cases_on_follow_up_htn_and_dm.male"),
        input("monthly_screening_reports.female",
              "diagnosed_cases_on_follow_up_htn_and_dm.female"),
      ]
    ),
    line_separator,
    header("monthly_screening_reports.cancer_screening"),
    sub_header("monthly_screening_reports.total_cancer_screening_oral"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "total_cancer_screening_oral.male"),
        input("monthly_screening_reports.female",
              "total_cancer_screening_oral.female"),
      ]
    ),
    sub_header("monthly_screening_reports.total_cancer_screening_breast"),
    group(
      item: [
        input("monthly_screening_reports.female",
              "total_cancer_screening_breast.female")
      ]
    ),
    sub_header("monthly_screening_reports.total_cancer_screening_cervical"),
    group(
      item: [
        input("monthly_screening_reports.female",
              "total_cancer_screening_cervical.female")
      ]
    ),
    separator,
    header("monthly_screening_reports.new_suspected_individuals"),
    sub_header("monthly_screening_reports.oral_cancer"),
    horizontal_group(
      item: [
        input("monthly_screening_reports.male",
              "oral_cancer.male"),
        input("monthly_screening_reports.female",
              "oral_cancer.female"),
      ]
    ),
    sub_header("monthly_screening_reports.breast_cancer"),
    group(
      item: [
        input("monthly_screening_reports.female",
              "breast_cancer.female"),
      ]
    ),
    sub_header("monthly_screening_reports.cervical_cancer"),
    group(
      item: [
        input("monthly_screening_reports.female",
              "cervical_cancer.female"),
      ]
    ),
  ])
end
















