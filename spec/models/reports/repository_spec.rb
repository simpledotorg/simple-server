require "rails_helper"

RSpec.describe Reports::Repository, type: :model, v2_flag: true do
  using StringToPeriod

  [true, false].each do |v2_flag|
    context "with reporting_schema_v2=>#{v2_flag}" do
      let(:v2_flag) { v2_flag }
      let(:organization) { create(:organization, name: "org-1") }
      let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
      let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

      let(:july_2020_range) { (Period.month(july_2020.advance(months: -24))..Period.month(july_2020)) }

      let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
      let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
      let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
      let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
      let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
      let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
      let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
      let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

      def refresh_views
        RefreshMaterializedViews.call
      end

      around do |example|
        original = Reports::Repository.use_schema_v2?
        Reports::Repository.use_schema_v2 = v2_flag
        with_reporting_time_zone { example.run }
        Reports::Repository.use_schema_v2 = original
      end

      context "earliest patient record" do
        it "returns the earliest between both assigned and registered if both exist" do
          facility_1, facility_2 = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
          district_region = facility_group_1.region
          other_facility = create(:facility)
          _patient_1 = create(:patient, recorded_at: july_2018, assigned_facility: facility_2)
          _patient_2 = create(:patient, recorded_at: june_1_2018, assigned_facility: other_facility, registration_facility: facility_1)
          facility_3 = create(:facility)

          region_with_no_patients = facility_3.region

          refresh_views

          regions = [district_region, region_with_no_patients, facility_1.region]
          repo = Reports::Repository.new(regions, periods: jan_2019.to_period)
          expect(repo.earliest_patient_recorded_at[district_region.slug]).to eq(june_1_2018.to_date)
          expect(repo.earliest_patient_recorded_at[facility_1.region.slug]).to eq(june_1_2018.to_date)
          expect(repo.earliest_patient_recorded_at[region_with_no_patients.slug]).to be_nil
        end
      end

      context "counts and rates" do
        it "gets assigned and registration counts for single facility region" do
          facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
          facility_1, facility_2 = facilities.take(2)

          default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
          _facility_1_registered = create_list(:patient, 2, default_attrs.merge(full_name: "controlled", recorded_at: jan_2019 + 1.day))
          create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019.advance(months: -4), assigned_facility: facility_1, registration_user: user)
          _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

          refresh_views

          repo = described_class.new(facility_1.region, periods: jan_2019.to_period)
          expected = {
            facility_1.slug => {
              jan_2019.to_period => 2
            }
          }
          expect(repo.monthly_registrations).to eq(expected)
        end

        it "gets assigned and registration counts for single facility_group region" do
          facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
          facility_1, facility_2 = facilities.take(2)
          facility_in_other_district = create(:facility)

          Timecop.freeze("January 1st 2019 05:30:30 IST") do
            _patient_registered_in_facility_1 = create(:patient, assigned_facility: facility_in_other_district, registration_facility: facility_1)
            _patient_assigned_to_facility_1 = create(:patient, assigned_facility: facility_1, registration_facility: facility_in_other_district)
            _patient_registered_and_assigned_to_facility_2 = create(:patient, assigned_facility: facility_2, registration_facility: facility_2)
            _patient_outside_facility_group = create(:patient, registration_facility: facility_in_other_district)
          end
          region = facility_group_1.region

          refresh_views

          range = jan_2019.to_period..("June 2019".to_period)
          repo = described_class.new(region, periods: range)
          expected_registered = {
            facility_group_1.slug => {
              jan_2019.to_period => 2,
              "Feb 2019".to_period => 0,
              "March 2019".to_period => 0,
              "April 2019".to_period => 0,
              "May 2019".to_period => 0,
              "June 2019".to_period => 0
            }
          }
          # handle slight difference in return values from v1 and v2 - in practice this won't matter,
          # because the v1 result set has a default of 0...so in effect they are the same
          if v2_flag
            expect(repo.monthly_registrations).to eq(expected_registered)
          else
            expect(repo.monthly_registrations[region.slug][jan_2019.to_period]).to eq(2)
          end
          expect(repo.adjusted_patients_without_ltfu[region.slug][Period.month("April 1st 2019")]).to eq(2)
        end

        it "gets assigned and registration counts for a range of periods" do
          facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
          facility_1, facility_2 = facilities.take(2)

          default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
          _facility_1_registered_in_jan_2019 = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_2019))
          _facility_1_registered_in_august_2018 = create_list(:patient, 2, default_attrs.merge(recorded_at: "August 1st 2018 00:00 UTC"))
          _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

          refresh_views

          slug = facility_1.slug
          repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))

          expect(repo.cumulative_assigned_patients[slug][Period.month("August 2018")]).to eq(2)
          expect(repo.cumulative_assigned_patients[slug][Period.month("Jan 2019")]).to eq(4)
          expect(repo.monthly_registrations[slug][Period.month("August 2018")]).to eq(2)
          expect(repo.monthly_registrations[slug][Period.month("Jan 2019")]).to eq(2)
          expect(repo.monthly_registrations[slug][july_2020.to_period]).to eq(0)
        end

        it "can count registrations and cumulative registrations by user" do
          facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
          facility_1 = facilities.first
          user_2 = create(:user)

          default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
          jan_1_2018 = Period.month("January 1 2018")
          _facility_1_registered_before_repository_range = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_1_2018.value))
          _facility_1_registered_in_jan_2019 = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_2019))
          _facility_1_registered_in_august_2018 = create_list(:patient, 2, default_attrs.merge(recorded_at: Time.parse("August 10th 2018")))
          _user_2_registered = create(:patient, full_name: "other user", recorded_at: jan_2019, registration_facility: facility_1, registration_user: user_2)

          refresh_views

          repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))
          expect(repo.monthly_registrations_by_user[facility_1.slug][jan_2019.to_period][user.id]).to eq(2)
          expect(repo.monthly_registrations_by_user[facility_1.slug][jan_2019.to_period][user_2.id]).to eq(1)
          expect(repo.monthly_registrations_by_user[facility_1.slug][july_2020.to_period]).to be_nil
        end

        it "gets registration and assigned patient counts for brand new regions with no data" do
          facility_1 = FactoryBot.create(:facility, facility_group: facility_group_1)
          slug = facility_1.region.slug
          repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)
          expect(repo.monthly_registrations).to eq({facility_1.slug => {}})
          expect(repo.controlled).to eq({facility_1.slug => {}})
          expect(repo.controlled_rates).to eq({facility_1.slug => {}})
          expect(repo.visited_without_bp_taken).to eq({slug => {}})
          expect(repo.visited_without_bp_taken_rate).to eq({slug => {}})
          expect(repo.visited_without_bp_taken_rate(with_ltfu: true)).to eq({slug => {}})
        end

        it "gets controlled counts and rates for single region" do
          facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
          facility_1, facility_2 = facilities.take(2)
          facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
          Timecop.freeze(jan_2020) do
            (facility_1_controlled << facility_2_controlled).map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
            end
            facility_1_uncontrolled.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago)
            end
          end
          refresh_views

          expected_counts = {
            facility_1.slug => {
              jan_2020.to_period => 2
            }
          }
          expected_rates = {
            facility_1.slug => {
              jan_2020.to_period => 50
            }
          }
          with_reporting_time_zone do
            repo = Reports::Repository.new(facility_1.region, periods: jan_2020.to_period)
            expect(repo.cumulative_assigned_patients[facility_1.slug][jan_2020.to_period]).to eq(4)
            expect(repo.controlled).to eq(expected_counts)
            expect(repo.controlled_rates).to eq(expected_rates)
          end
        end

        it "gets controlled counts and rates for one month" do
          facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1).sort_by(&:slug)
          facility_1, facility_2, facility_3 = *facilities.take(3)
          regions = facilities.map(&:region)

          facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

          Timecop.freeze(jan_2020) do
            (facility_1_controlled << facility_2_controlled).map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
            end
            facility_1_uncontrolled.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago)
            end
          end

          refresh_views

          jan = Period.month(jan_2020)
          repo = Reports::Repository.new(regions, periods: Period.month(jan))
          controlled = repo.controlled
          uncontrolled = repo.uncontrolled
          expect(controlled[facility_1.slug][jan]).to eq(2)
          expect(controlled[facility_2.slug][jan]).to eq(1)
          expect(controlled[facility_3.slug][jan]).to eq(0)
          expect(uncontrolled[facility_1.slug][jan]).to eq(2)
          expect(uncontrolled[facility_2.slug][jan]).to eq(0)
          expect(uncontrolled[facility_3.slug][jan]).to eq(0)
        end

        it "gets controlled info for range of month periods" do
          facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1)
          facility_1, facility_2, facility_3 = *facilities.take(3)
          regions = facilities.map(&:region)

          controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
          controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: create(:facility), registration_user: user)

          Timecop.freeze(jan_2020) do
            controlled_in_jan_and_june.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 3.days.from_now, user: user)
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
            end
            uncontrolled_in_jan.map { |patient| create(:bp_with_encounter, :hypertensive, facility: facility_2, patient: patient, recorded_at: 4.days.from_now) }
            create(:bp_with_encounter, :under_control, facility: patient_from_other_facility.assigned_facility, patient: patient_from_other_facility, recorded_at: 4.days.from_now)
          end

          Timecop.freeze(june_1_2020) do
            controlled_in_jan_and_june.map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago, user: user)
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 35.days.ago, user: user)
            end

            create(:bp_with_encounter, :under_control, facility: facility_3, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

            uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, assigned_facility: facility_1, registration_user: user)
            uncontrolled_in_june.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 1.days.ago, user: user)
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
            end
          end

          refresh_views

          start_range = july_2020.advance(months: -24)
          range = (Period.month(start_range)..Period.month(july_2020))
          repo = Reports::Repository.new(regions, periods: range)
          result = repo.controlled

          facility_1_results = result[facility_1.slug]
          range.each do |period|
            # Not sure we really care about this behavior
            # expect(facility_1_results[period]).to_not be_nil
          end
          expect(facility_1_results[Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
          expect(facility_1_results[Period.month(june_1_2020)]).to eq(3)
        end

        it "excludes dead patients from control info" do
          facility_1 = FactoryBot.create_list(:facility, 1, facility_group: facility_group_1).first
          facility_1_controlled = create_list(:patient, 1, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          facility_1_controlled_dead = create_list(:patient, 1, status: :dead, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

          Timecop.freeze(jan_2020) do
            facility_1_controlled.concat(facility_1_controlled_dead).map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
            end
          end

          refresh_views
          jan = Period.month(jan_2020)
          repo = Reports::Repository.new(facility_1, periods: Period.month(jan))
          controlled = repo.controlled
          uncontrolled = repo.uncontrolled

          region = facility_1.region
          expect(controlled[region.slug].fetch(jan)).to eq(1)
          expect(uncontrolled[region.slug].fetch(jan)).to eq(0)
        end

        it "gets visit without BP taken counts without LTFU" do
          facility_1 = FactoryBot.create_list(:facility, 1, facility_group: facility_group_1).first
          # Since we are reporting for Jan 2020, this patient is lost to follow up -- they have been registered for 12 months but have no BPs taken
          visit_with_no_bp_and_ltfu = create(:patient, full_name: "visit_with_no_bp_and_ltfu", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          # This user is NOT lost to follow up, as they have not been registered over 12 months
          visit_with_no_bp_and_not_ltfu = create(:patient, full_name: "visit_with_no_bp_and_not_ltfu", recorded_at: "June 2019", assigned_facility: facility_1, registration_user: user)
          visit_with_bp = create(:patient, full_name: "visit_with_bp", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

          Timecop.freeze(jan_2020) do
            create(:appointment, patient: visit_with_no_bp_and_ltfu, facility: facility_1, user: user)
            create(:blood_sugar, patient: visit_with_no_bp_and_not_ltfu, facility: facility_1, user: user)
            create(:bp_with_encounter, :under_control, facility: facility_1, patient: visit_with_bp, user: user)
          end

          refresh_views
          jan = Period.month(jan_2020)
          repo = Reports::Repository.new(facility_1, periods: jan)
          expect(repo.visited_without_bp_taken[facility_1.region.slug][jan]).to eq(1)
        end
      end

      context "follow ups" do
        it "returns correct per region results with optional group_by" do
          facility_1, facility_2 = create_list(:facility, 2)
          regions = [facility_1.region, facility_2.region]

          Timecop.freeze("May 10th 2021") do
            periods = (6.months.ago.to_period..1.month.ago.to_period)
            patient_1, patient_2 = create_list(:patient, 2, :hypertension, recorded_at: 10.months.ago)
            user_1 = create(:user)
            user_2 = create(:user)

            create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_1, user: user_1)
            create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_2, user: user_2)
            create(:bp_with_encounter, recorded_at: 2.months.ago, facility: facility_1, patient: patient_2, user: user_2)
            create(:bp_with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient_1)

            repo = Reports::Repository.new(regions, periods: periods)
            repo_2 = Reports::Repository.new(regions, periods: periods)

            expected_grouped_by_user = {
              Period.month("February 1st 2021") => {
                user_1.id => 1,
                user_2.id => 1
              },
              Period.month("March 1st 2021") => {
                user_1.id => 0,
                user_2.id => 1
              }
            }

            expect(repo.hypertension_follow_ups[facility_1.region.slug]).to eq({
              Period.month("February 1st 2021") => 2, Period.month("March 1st 2021") => 1
            })
            expect(repo.hypertension_follow_ups[facility_2.region.slug]).to eq({Period.month("April 1st 2021") => 1})
            expect(repo.hypertension_follow_ups(group_by: "blood_pressures.user_id")[facility_1.region.slug]).to eq(expected_grouped_by_user)
            expect(repo_2.hypertension_follow_ups(group_by: "blood_pressures.user_id")[facility_1.region.slug]).to eq(expected_grouped_by_user)
          end
        end
      end

      context "ltfu" do
        it "counts ltfu for patients who never have a BP taken" do
          facility = create(:facility, facility_group: facility_group_1)
          slug = facility.region.slug
          other_facility = create(:facility, facility_group: facility_group_1)
          # patient who never has a BP taken so they are LTFU in Jan 1st 2019
          _ltfu_1 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "Jan 1st 2018 00:00:00 UTC", registration_user: user)
          # patient who becomes LTFU September 2019
          ltfu_2 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "July 1st 2018 00:00:00 UTC", registration_user: user)
          create(:bp_with_encounter, recorded_at: "July 1st 2018 00:00:00", facility: facility, patient: ltfu_2, user: user)
          create(:bp_with_encounter, recorded_at: "September 1st 2018 00:00:00", facility: other_facility, patient: ltfu_2, user: user)
          # patient who is not LTFU
          non_ltfu_patient = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "July 1st 2019 00:00:00 UTC", registration_user: user)
          create(:bp_with_encounter, recorded_at: "July 1st 2019 00:00:00", facility: facility, patient: non_ltfu_patient, user: user)

          refresh_views

          jan_2020_range = (Period.month(jan_2020.advance(months: -24))..Period.month(jan_2020))
          repo = Reports::Repository.new(facility.region, periods: jan_2020_range)
          result = repo.ltfu[slug]
          ("January 2018".to_period.."December 2018".to_period).each { |period| expect(result[period]).to eq(0) }
          ("January 2019".to_period.."August 2019".to_period).each { |period| expect(result[period]).to eq(1) }
          ("September 2019".to_period.."January 2020".to_period).each { |period| expect(result[period]).to eq(2) }
        end
      end

      context "missed visits" do
        it "counts missed visits for patients with no BPs taken" do
          facility = create(:facility, facility_group: facility_group_1)
          slug = facility.region.slug
          # patient who never has a BP taken, so they become a missed visit in April 2018
          _missed_visit = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "January 1st 2018 00:00:00 UTC", registration_user: user)
          patient_1_with_visits = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "January 1st 2018 00:00:00 UTC", registration_user: user)
          patient_2_with_visits = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "January 1st 2018 00:00:00 UTC", registration_user: user)
          [3, 6, 9, 12].product(["2018", "2019"]).each do |month, year|
            create(:bp_with_encounter, :under_control, facility: facility, patient: patient_1_with_visits, recorded_at: "#{year}-#{month}-1st 08:00:00 UTC")
            create(:bp_with_encounter, :under_control, facility: facility, patient: patient_2_with_visits, recorded_at: "#{year}-#{month}-1st 08:00:00 UTC")
          end

          refresh_views

          jan_2020_range = (Period.month(jan_2020.advance(months: -24))..Period.month(jan_2020))
          repo = Reports::Repository.new(facility.region, periods: jan_2020_range)

          months_with_one_missed_visit = ("April 2018".to_period...jan_2019.to_period).entries
          jan_2020_range.each do |period|
            if period.in?(months_with_one_missed_visit)
              expected_count = 1
              expected_rate = 33
            else
              expected_count = 0
              expected_rate = 0
            end

            count = repo.missed_visits_without_ltfu[slug][period]
            rate = repo.missed_visits_without_ltfu_rates[slug][period]
            expect(count).to eq(expected_count), "expected #{period} to have missed visits of #{expected_count} but got #{count}"
            expect(rate).to eq(expected_rate), "expected #{period} to have missed visits rate of #{expected_rate} but got #{rate}"
          end
        end

        it "counts missed visits without ltfu" do
          facility = create(:facility, facility_group: facility_group_1)
          slug = facility.region.slug
          # patient w/ missed visit starting in April 2018 who is LTFU as of Jan 2019
          missed_visit_1 = FactoryBot.create(:patient, assigned_facility: facility, registration_facility: facility, recorded_at: "Jan 1st 2018 08:00:00 UTC", registration_user: user)
          create(:bp_with_encounter, :under_control, facility: facility, patient: missed_visit_1, recorded_at: "Jan 1st 2019 08:00:00 UTC")

          # patient who never has a BP taken, and is missed visit from April 2018 to Dec 2018
          _missed_visit_2 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "Jan 1st 2018 00:00:00 UTC", registration_user: user)

          refresh_views

          jan_2020_range = (Period.month(jan_2020.advance(months: -24))..Period.month(jan_2020))
          repo = Reports::Repository.new(facility.region, periods: jan_2020_range)
          result = repo.missed_visits_without_ltfu[slug]

          ("January 2018".to_period.."March 2018".to_period).each { |period| expect(result[period]).to eq(0) }
          ("April 2018".to_period.."December 2018".to_period).each { |period| expect(result[period]).to eq(2) }
          ("January 2019".to_period.."March 2019".to_period).each { |period| expect(result[period]).to eq(0) }
          ("April 2019".to_period.."December 2019".to_period).each { |period| expect(result[period]).to eq(1) }
          expect(result["January 2020".to_period]).to eq(0)
        end
      end

      context "caching", skip: v2_flag do
        let(:facility_1) { create(:facility, name: "facility-1") }

        it "creates cache keys" do
          repo = Reports::Repository.new(facility_1, periods: Period.month("June 1 2019")..Period.month("Jan 1 2020"))
          cache_keys = repo.send(:cache_entries, :controlled).map(&:cache_key)
          cache_keys.each do |key|
            expect(key).to include("controlled")
          end
        end

        it "memoizes calls to queries" do
          controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          Timecop.freeze(jan_2020) do
            controlled_in_jan.map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
            end
          end
          refresh_views

          repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)

          allow(repo.schema).to receive(:region_period_cached_query).and_call_original
          expect(repo.schema).to receive(:region_period_cached_query).with(:controlled).exactly(1).times.and_call_original

          3.times { _result = repo.controlled }
          3.times { _result = repo.controlled_rates }
        end

        it "caches region_period entries only as far back as there is data" do
          _controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

          repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)
          keys = repo.send(:cache_entries, :controlled)
          periods = keys.map(&:period)
          expected_periods = (jan_2019.to_period..july_2020.to_period).to_a
          expect(periods).to eq(expected_periods)
        end

        it "will not ignore memoization when bust_cache is true" do
          controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          Timecop.freeze(jan_2020) do
            controlled_in_jan.map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
            end
          end
          refresh_views

          RequestStore[:bust_cache] = true
          repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)
          expect(repo.schema).to receive(:region_period_cached_query).with(:controlled).exactly(1).times

          3.times { _result = repo.controlled }
        end
      end

      context "legacy control specs" do
        it "works for very old dates" do
          facility_1 = create(:facility)
          patient = create(:patient, registration_facility: facility_1, recorded_at: jan_2020.advance(months: -4))
          create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: facility_1)
          refresh_views

          ten_years_ago = patient.recorded_at.advance(years: -10).to_period
          range = ten_years_ago..(ten_years_ago.advance(months: 12))
          repo = Reports::Repository.new(facility_1, periods: range)

          expect(repo.adjusted_patients[facility_1.slug]).to eq({})
          # cumulative registrations returns all summed registrations for all months we have in reporting_months...
          # not sure who should be responsible for trimming the result set
          expect(repo.cumulative_registrations[facility_1.slug]).to eq({})
        end
      end

      context "v2" do
        it "gets correct controlled counts" do
          facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1)
          facility_1, facility_2, facility_3 = *facilities.take(3)
          regions = facilities.map(&:region)

          controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
          controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
          patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: create(:facility), registration_user: user)

          Timecop.freeze(jan_2020) do
            controlled_in_jan_and_june.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 3.days.from_now, user: user)
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
            end
            uncontrolled_in_jan.map { |patient| create(:bp_with_encounter, :hypertensive, facility: facility_2, patient: patient, recorded_at: 4.days.from_now) }
            create(:bp_with_encounter, :under_control, facility: patient_from_other_facility.assigned_facility, patient: patient_from_other_facility, recorded_at: 4.days.from_now)
          end

          Timecop.freeze(june_1_2020) do
            controlled_in_jan_and_june.map do |patient|
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago, user: user)
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 35.days.ago, user: user)
            end

            create(:bp_with_encounter, :under_control, facility: facility_3, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

            uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, assigned_facility: facility_1, registration_user: user)
            uncontrolled_in_june.map do |patient|
              create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 1.days.ago, user: user)
              create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
            end
          end

          Timecop.freeze(july_2020) do
            refresh_views
          end

          with_reporting_time_zone do
            start_range = july_2020.advance(months: -24)
            range = (Period.month(start_range)..Period.month(july_2020))
            repo_v1 = Reports::Repository.new(regions, periods: range, reporting_schema_v2: false)
            repo_v2 = Reports::Repository.new(regions, periods: range, reporting_schema_v2: true)
            expect(repo_v2.controlled[facility_1.slug]).to eq(repo_v1.controlled[facility_1.slug])
            expect(repo_v2.uncontrolled[facility_1.slug]).to eq(repo_v1.uncontrolled[facility_1.slug])
            result = repo_v2.controlled

            facility_1_results = result[facility_1.slug]

            expect(facility_1_results[Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
            expect(facility_1_results[Period.month(june_1_2020)]).to eq(3)
          end
        end
      end
    end
  end
end
