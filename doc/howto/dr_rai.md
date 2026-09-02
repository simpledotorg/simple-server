# Dr. Rai

There is no architecture doc for Dr. Rai under `doc/arch/` at the time of writing. This guide is the only reference beyond the code itself, so treat it as the source of truth until (if) an ADR is written.

### 1. What is Dr. Rai

Dr. Rai is a quarterly reporting and action-planning feature for facility staff. For a facility (or other region), it computes a set of clinical quality indicators — BP control-adjacent measures such as contact-overdue patients, titration, statins prescription rate, and BP fudging (a data-integrity indicator, see below) — compares each indicator's current value against a target, and lets facility staff record an "action plan" (a statement + a list of actions) to close the gap. "Dr. Rai" is the in-product persona name used for this report; there is no separate service or process by that name, it is presented through the `Dashboard::DrRaiReport` view component.

**Domain models**

- `app/models/dr_rai.rb` — just sets `table_name_prefix` to `dr_rai_` for everything in the `DrRai` namespace. Not a model itself.
- `app/models/dr_rai/indicator.rb` — `DrRai::Indicator < ApplicationRecord`, backed by the `dr_rai_indicators` table using Rails single-table inheritance (a `type` column, no other meaningful columns). The base class documents itself as incomplete by design: it defines the data-access methods (`numerator`, `denominator`, `numerators`, `denominators`, `quarterlies`, `has_action_plans?`) but every indicator subclass must supply `datasource`, `display_name`, `target_type_frontend`, `numerator_key`, `denominator_key`, `unit`, `action_passive`, `action_active`, and `is_supported?`. `validates :type, uniqueness: true` means there can only ever be one row per indicator subclass — the row itself has no other required attributes.
  - `app/models/dr_rai/contact_overdue_patients_indicator.rb` — sources from `Reports::RegionSummary`/`RegionSummaryAggregator` (the existing reporting pipeline), via `Indicator#quarterlies`. No dedicated `DrRai::Data` table or query factory; it just reads from the existing rollup tables.
  - `app/models/dr_rai/titration_indicator.rb`, `app/models/dr_rai/statins_indicator.rb`, `app/models/dr_rai/bp_fudging_indicator.rb` — all three are "SQL-backed" indicators. Each reads from its own `DrRai::Data::*` table (populated nightly, see section 2) via `include DrRai::Chartable`'s `chartable` class method.
- `app/models/dr_rai/target.rb` — `DrRai::Target < ApplicationRecord`, also STI (`type` column) via the `TYPES` hash (`"percent" => DrRai::PercentageTarget`, `"numeric" => DrRai::NumericTarget`, `"boolean" => DrRai::BooleanTarget`, `"custom" => DrRai::CustomTarget`). `belongs_to :indicator`. `period` is validated against `/\AQ\d-\d{4}\Z/` (e.g. `"Q2-2024"`) — targets and action plans are always scoped to a quarter, never a month.
  - `boolean_target.rb` — the only subclass with a working `achieved_for?` (returns `completed`).
  - `numeric_target.rb`, `percentage_target.rb`, `custom_target.rb` — all three `achieved_for?` implementations `raise "Unimplemented"`. Don't assume this method works for any indicator currently in production; nothing in the live code path calls `achieved_for?` today (progress is computed directly on `ActionPlan#progress` instead, see below).
- `app/models/dr_rai/action_plan.rb` — `DrRai::ActionPlan < ApplicationRecord`, belongs to a `dr_rai_indicator`, a `dr_rai_target`, and a `region`. This is the record facility staff create/edit. Key methods:
  - `numerator`/`denominator`/`progress` compute percent-complete against the target for the target's quarter.
  - `current_ratio`/`previous_ratio`/`ratio_change_percentage`/`is_better?` are BP-Fudging-specific (`custom_target?` guards them, returning `nil` for all other target types). For BP Fudging specifically, a *lower* ratio is better (hardcoded in `is_better?`).
  - `target_uses_statement?` (backing the `statement` presence validation) is true only for indicators using `DrRai::Target::NEEDS_STATEMENT` (percent/numeric targets) — boolean and custom targets don't require a statement.
- `app/models/dr_rai/data.rb` — namespacing module only (`table_name_prefix "dr_rai_data_"`), like `dr_rai.rb`.
  - `app/models/dr_rai/data/titration.rb`, `data/statin.rb`, `data/bp_fudging.rb` — plain `ApplicationRecord`s holding pre-aggregated numbers, refreshed nightly by rake tasks (section 2). Each defines a `default_scope` limiting rows to roughly the trailing year/10 months, plus an `insert_window` scope used by `DrRai::DataService` to decide whether to insert or upsert (see the caution in section 2 about backfilling outside this window).

**Concerns**

- `app/models/concerns/dr_rai/calculatable.rb` (`DrRai::Calculatable`) — included by both `Indicator` and `ActionPlan`. It only declares two zero-arg abstract markers, `numerator` and `denominator`, both of which raise `"Unimplemented"`. In practice every indicator overrides these with the two-arg versions defined in the base `Indicator` class (`numerator(region, the_period, ...)`), so the abstract zero-arg versions in the concern are never actually called on `Indicator`; `ActionPlan` does define real zero-arg `numerator`/`denominator` methods that shadow the concern's stubs. Treat `Calculatable` as documentation of intent ("every indicator/action-plan-like thing must expose these two things"), not as working shared code.
- `app/models/concerns/dr_rai/chartable.rb` (`DrRai::Chartable`) — included by the three `DrRai::Data::*` models. It provides a single class method, `chartable`, which reads every row of the table and groups it into a nested hash: `{ outer_grouping => { quarter_period => { internal_key => summed_value } } }`. The three class-level declarations (`chartable_internal_keys`, `chartable_period_key`, `chartable_outer_grouping`) configure this per model — see the "Grouping column" table in section 3, because the outer-grouping column name and what it actually contains differs across the three tables.

**Query layer**

- `app/queries/dr_rai/query_factory.rb` — `DrRai::QueryFactory.for(klazz, from:, to:)` dispatches to the concrete factory based on which `DrRai::Data::*` class you pass it (`Data::Titration` → `TitrationQueryFactory`, `Data::Statin` → `StatinsQueryFactory`, `Data::BpFudging` → `BpFudgingQueryFactory`; anything else raises `"Unsupported"`). Each concrete factory implements `inserter` (plain `INSERT ... SELECT`) and `updater` (`INSERT ... ON CONFLICT DO UPDATE`, used to keep the data tables idempotent night over night).
- `app/queries/dr_rai/titration_query_factory.rb` — reads `reporting_patient_states` joined to `reporting_facilities`, counting patients due for a follow-up in their titration month who were actually titrated (`months_since_bp = 0`, `last_bp_state = 'uncontrolled'`). Includes a synthetic `'average'` row across all facilities.
- `app/queries/dr_rai/statins_query_factory.rb` — the most complex of the three: identifies diabetes/CVD-risk patients under care (prior stroke/heart attack, or diabetes and age ≥ 40) from `reporting_patient_states`, then checks `prescription_drugs` (matched by `name ilike '%statin%'`) for a prescription in the same month. It aggregates both per-facility (`assigned_facility_slug`) and per-organization (`assigned_organization_slug`), unioning both into the same table (see the `aggregate_root` caution in section 3).
- `app/queries/dr_rai/bp_fudging_query_factory.rb` — reads `blood_pressures` directly (not the `reporting_*` rollups), bucketing systolic readings into "just under the 140 threshold" (130–139, the numerator) vs. "just over" (140–149, the denominator) per facility per quarter. A high numerator/denominator ratio is a proxy signal that a facility may be recording BPs just under the treatment threshold to avoid escalating care — hence "fudging." The comment in the file notes this is adapted from an existing Metabase query.

`app/services/dr_rai/data_service.rb` (`DrRai::DataService.populate(klazz, timeline:)`) is the only caller of the query factories in application code; it decides whether to run `inserter` or `updater` based on `klazz.insert_window(timeline).count == 0`, then executes the SQL directly via `ApplicationRecord.connection.exec_query`.

**UI surface**

The whole feature renders through `app/components/dashboard/dr_rai_report.rb` / `.html.erb` (`Dashboard::DrRaiReport`, a ViewComponent), embedded in three places:

- `app/views/reports/regions/show.html.erb:111-112` — the main facility report page.
- `app/views/reports/regions/diabetes.html.erb:7-8` — the diabetes/CVD report page.
- `app/views/api/v3/analytics/user_analytics/show.html.erb:22-29` — the mobile app's "Progress" tab (rendered server-side as HTML inside the app), using the component's "lite" mode (`lite = true`, fourth constructor argument) which only shows existing action plans read-only and skips the indicator-browsing/creation UI (`custom_indicators` returns `nil` when `@lite` is true).

`app/controllers/dr_rai/action_plans_controller.rb` (routed under `namespace :dr_rai do resources :action_plans, only: [:create, :update, :destroy] end` in `config/routes.rb`) handles create/update/destroy of action plans. There is no `index`/`show` action — action plans are only ever listed as part of rendering `Dashboard::DrRaiReport`.

**Feature flags**

Three Flipper flags gate this feature, all checked directly in view/controller/component code (`grep -rn "Flipper" app/components/dashboard/dr_rai_report.rb app/controllers/dr_rai app/views/reports/regions app/views/api/v3/analytics/user_analytics`):

| Flag | Checked where | Actor passed? | Effect |
|---|---|---|---|
| `dr_rai_reports` | `app/views/reports/regions/show.html.erb:111`, `diabetes.html.erb:7` | `current_admin` (a `User` — see below) | Shows/hides the full Dr. Rai report block on the two dashboard report pages, per admin. |
| `dr_rai_progress` | `app/views/api/v3/analytics/user_analytics/show.html.erb:22` | none | Global on/off switch for the read-only action plan block on the mobile app's Progress tab, for every facility/user. |
| `dr_rai_manual_edit` | `app/components/dashboard/dr_rai_report.rb:60`, `app/controllers/dr_rai/action_plans_controller.rb:60` | none | Global override that disables the edit-window restriction on action plans (see below). Not a per-user or per-facility toggle — enabling it in Flipper affects every admin/action plan in the deployment. |

`dr_rai_reports` is the only one that takes an actor. `Flipper.enabled?(:dr_rai_reports, current_admin)` works because `current_admin` (set in `app/controllers/admin_controller.rb`) resolves to a `User` record, and `User` includes `app/models/concerns/flipperable.rb`, which gives it `flipper_id` (`"User;<id>"`). This is what lets you enable `dr_rai_reports` for specific admins (or groups/percentages of them) from the Flipper UI, mounted at `/flipper` (gated to power users in `config/routes.rb`) — there is no dr_rai-specific admin screen for flags.

`dr_rai_progress` and `dr_rai_manual_edit` are checked with no actor argument at all, so they are plain global booleans — Flipper's per-actor/group/percentage rollout machinery doesn't apply to them regardless of what's configured in the Flipper UI for those flags. `commit 646d66f9 ("fix(Dr. Rai Reports): Use one flag per site")` explicitly removed the second, actor-scoped `dr_rai_reports` check from the progress-tab view because "both flags needed to be enabled" was confusing, leaving `dr_rai_progress` as a single unconditional flag for that surface.

There is also a **code-level, non-Flipper gate**: `TitrationIndicator#is_supported?` (`app/models/dr_rai/titration_indicator.rb`) hardcodes per-country logic on `CountryConfig.current[:name]` — it only returns `true` for Bangladesh (region path includes `"nhf"`), Ethiopia (region path excludes anything containing `"non_rtsl"`), Sri Lanka (region path includes `"sri_lanka_organization"`), and India (unconditionally `true`); every other country gets `false`, silently hiding the Titration indicator even with `dr_rai_reports` enabled. `commit 56375460 ("fix(Dr. Rai Reports): Turn on for SBX")` is a real example of this biting: the India `when` clause was missing, so the sandbox environment (configured as India) showed no Titration indicator until that one-line fix landed. **If you stand this feature up in a country not in that list, add a branch here or Titration will never appear, and nothing will log or error to tell you why.**

**Action plan edit rules**

Editing an action plan (`PATCH /dr_rai/action_plans/:id`) is restricted by a "edit window" enforced in two places that must agree: `Dashboard::DrRaiReport#action_plans_editable?` (controls whether the edit UI renders at all) and `DrRai::ActionPlansController#enforce_action_plan_edit_window` (a `before_action`, the actual server-side enforcement — the component-level check is UI-only and not a security boundary by itself).

As of `commit 783ec663 ("fix: honor manual edit override and last-month edit rule for action plans")`, the rule is:

```ruby
# app/controllers/dr_rai/action_plans_controller.rb
def enforce_action_plan_edit_window
  return if Flipper.enabled?(:dr_rai_manual_edit)

  target_period = Period.new(type: :quarter, value: @dr_rai_action_plan.target.period)
  current_period = Period.current.to_quarter_period

  unless target_period == current_period && Date.current.month != current_period.end.month
    head :forbidden
  end
end
```

In plain terms: an action plan can be updated only if (a) its target's quarter is the *current* quarter, and (b) today is not in the last calendar month of that quarter. So for a Q2 (Apr–Jun) action plan, edits are allowed in April and May but blocked in June, and blocked entirely once Q3 starts. This replaced an earlier, stricter rule that only allowed edits in the *first* month of the quarter — `Date.current.month == current_period.begin.month` became `Date.current.month != current_period.end.month`. Note this is a month-number comparison (`.month`, an integer 1–12) with no year component; it is only correct because it's always ANDed with the `target_period == current_period` check. Do not use `Date.current.month != current_period.end.month` on its own anywhere — across a year boundary it would be wrong.

The `dr_rai_manual_edit` flag, added by `commit 2e38a8e7 ("feat(Dr. Rai Reports): Add edit override")`, bypasses this window entirely (`return` before any period check), on both the component (so the edit UI shows) and the controller (so the `PATCH` isn't rejected). It's meant for the team to manually test/fix action plans outside the normal quarter/month constraints. It is a blunt instrument: enabling it doesn't scope to one admin, one facility, or one action plan — every action plan everywhere becomes editable until you disable it again.

The edit window only applies to `update`. `create` and `destroy` have no equivalent `before_action` and are not time-restricted at all (they're still gated by `authorize_user`/`authorize_edit_action_plans`, which check the admin can view/edit reports for that region, but not by quarter or month).

### 2. How to set up Dr. Rai for the first time on a Simple instance

**2.1 Run the migrations**

Dr. Rai's schema is entirely contained in migrations already in `db/migrate/` — there's nothing to write, just run them as part of a normal deploy (`rails db:migrate`, or however this instance runs migrations). The tables involved:

- `dr_rai_indicators` — one row per indicator subclass, added via `20250619104804_create_dr_rai_indicators.rb` and reshaped by four follow-up migrations (adds `type`, drops `title`, drops/re-adds `region`). Final shape has no required columns beyond `id`/`type`/timestamps.
- `dr_rai_targets` — `20250618201739_create_dr_rai_targets.rb`, later migrations change `period` from a `jsonb` column to a plain string (`20250619225935`) and make `dr_rai_indicators_id` nullable (`20251211073126`).
- `dr_rai_action_plans` — `20250619195214_create_dr_rai_action_plans.rb`.
- `dr_rai_data_titrations` — `20250813062338` (create) + `20250813064810` (adds `deleted_at`) + `20250923223358` (unique index on `month_date, facility_name`).
- `dr_rai_data_statins` — `20250827134615` (create) + `20250828111954` (unique index on `month_date, aggregate_root`).
- `dr_rai_data_bp_fudgings` — `20251125090819` (create, with a unique index on `state, district, slug, quarter`).

Note: `db/migrate/20260209112204_create_patient_scores.rb` and `app/controllers/api/v4/patient_scores_controller.rb` are **not** part of Dr. Rai despite the naming similarity to "scores" — that's a separate, unrelated `api/v4` feature. Don't assume it needs to run alongside this setup.

**2.2 Enable the Flipper flags**

There is no rake task or admin page specific to Dr. Rai for this — flags are managed through the generic Flipper UI mounted at `/flipper` (restricted to power users, `config/routes.rb`), or via `rails console` using `Flipper.enable(...)`/`Flipper.enable_actor(...)`.

1. To show the report on the two dashboard pages (`reports/regions/show` and `reports/regions/diabetes`), enable `dr_rai_reports` for the admins who should see it: `Flipper.enable_actor(:dr_rai_reports, some_user)` for a specific `User`, or use the Flipper UI's percentage/group rollout against the `User` actor type. Remember `current_admin` resolves to a `User`, so actor-based enablement must target `User` records, not `Admin`/`EmailAuthentication`.
2. To surface action plans read-only on the mobile app's Progress tab, enable `dr_rai_progress`. This flag takes **no actor** — `Flipper.enable(:dr_rai_progress)` turns it on for every facility at once. There's no way to scope this to a subset of facilities with the current code.
3. Leave `dr_rai_manual_edit` disabled in normal operation. Only enable it (again, globally — no actor) when you need to manually fix or test-edit an action plan outside its normal edit window, and disable it again afterward.

Enabling `dr_rai_reports` alone is not sufficient for a facility to see every indicator — see the `is_supported?` per-country gate on Titration in section 1, and the per-indicator data-availability notes in 2.4.

**2.3 Make sure the nightly data jobs are scheduled**

`config/schedule.rb` (whichever cron runner this deploys with, e.g. `whenever`/sidekiq-cron) already defines the job:

```ruby
every :day, at: local("03:00 am"), roles: [:cron] do
  %w[
    titration
    statins
    bp_fudging
  ].each do |indicator|
    rake "dr_rai:populate_#{indicator}_data"
  end
end
```

This must be running on a host with the `:cron` role for the Titration, Statins, and BP Fudging indicators to have any data — `ContactOverduePatientsIndicator` is the exception, since it reads from the existing `Reports::RegionSummary` pipeline instead of one of these tables. Confirm this job is scheduled for real (check whatever job scheduler/dashboard this deployment uses — `whenever`'s crontab, sidekiq-cron UI, etc.) after standing up a new instance.

This job must run *after* `db:refresh_reporting_views` (also scheduled in `config/schedule.rb`, at `REPORTS_REFRESH_TIME`), because the Titration and Statins queries read from `reporting_patient_states`, `reporting_facilities`, `reporting_patient_visits`, and `reporting_months` — all materialized/rollup tables refreshed by that task. If the schedule ever gets reordered, Dr. Rai's nightly numbers will be stale or empty without any error.

The three underlying rake tasks (`lib/tasks/dr_rai.rake`) can also be run by hand for a manual backfill:

```
rails dr_rai:populate_titration_data[2025-01-01,2025-06-30]
rails dr_rai:populate_statins_data[2025-01-01,2025-06-30]
rails dr_rai:populate_bp_fudging_data[2025-01-01,2025-06-30]
```

Both arguments are optional and default to `1.year.ago..Date.today`. **Caution:** each `DrRai::Data::*` model has a `default_scope` restricting it to roughly the last year (Titration/Statins) or the last 10 months (BP Fudging), and `DrRai::DataService` decides whether to run its `inserter` (plain `INSERT`) or `updater` (`INSERT ... ON CONFLICT`) query based on `klazz.insert_window(timeline).count`, which is layered on top of that `default_scope`. If you backfill a date range entirely outside the model's `default_scope` window, that count will always read `0` — even if rows for that period already exist from an earlier run — causing it to pick the plain `inserter`, which has no conflict handling and will fail against the unique index if any of those rows are already present. Backfills of old historical data should be done with direct SQL or by temporarily widening the `default_scope`, not through this rake interface.

**2.4 Environment variables and config toggles**

There are no Dr. Rai-specific environment variables or config files. The only external config input is `CountryConfig.current[:name]`, consumed by `TitrationIndicator#is_supported?` (section 1) to decide whether Titration shows up at all for a given deployment's country. Indirectly, `REPORTS_REFRESH_TIME`/`REPORTS_REFRESH_FREQUENCY` (whatever this deployment sets them to, in `config/schedule.rb`) matter because of the cron-ordering dependency in 2.3 — Dr. Rai's nightly jobs must run after the reporting views refresh, not because of anything Dr. Rai itself reads.

**2.5 Seed data / targets**

There is no seed file, YAML config, or console-driven setup script for indicators or targets — don't look for one, because it doesn't exist. Concretely:

- **Indicators** are created as literal rows: one row per subclass (e.g. `DrRai::ContactOverduePatientsIndicator.create!`, `DrRai::TitrationIndicator.create!`), typically done once via `rails console` against production. All four indicator subclasses currently ship in the codebase already have (or are expected to have) a row; if a fresh environment's `dr_rai_indicators` table is empty, nothing will render even with all flags on and cron jobs running, because `Dashboard::DrRaiReport#custom_indicators` iterates `DrRai::Indicator.all`.
- **Targets** (the per-quarter goal a facility is trying to hit) are *not* pre-seeded — they're created ad hoc, per facility per quarter, by `DrRai::ActionPlansController#hydrate_plan` when a facility staff member creates their first action plan for an indicator in a given quarter. There's no way to pre-populate targets for facilities that haven't yet created an action plan.
- There are no other thresholds/config files to seed.

**2.6 Verifying the setup**

Once migrations have run, `dr_rai_reports` is enabled for a test admin, indicator rows exist, and the nightly (or manually-run) data-population rake tasks have populated the three `dr_rai_data_*` tables:

1. Log in as an admin who has `dr_rai_reports` enabled, with access to at least one facility.
2. Go to that facility's report page (`reports/regions/:id` with `report_scope=facility`, or the diabetes report page). You should see a Dr. Rai report block with one card per supported indicator for that region (contact-overdue patients always shows if the facility has any `Reports::RegionSummary` data; Titration only shows if `is_supported?` returns true for the facility's country; Statins and BP Fudging show if their respective `dr_rai_data_*` tables have rows for that facility/org).
3. Create an action plan against one of the indicators; it should immediately appear with a progress percentage.
4. If `dr_rai_progress` is also enabled, that same action plan should appear read-only in the mobile app's Progress tab for that facility (`api/v3/analytics/user_analytics#show`).
5. If nothing shows up despite flags being on, check in this order: does `dr_rai_indicators` have rows; does `region.source_type == "Facility"` for the region you're viewing (org/state-level regions never show custom indicators); for Titration specifically, does `CountryConfig.current[:name]` match one of the four supported countries; do the `dr_rai_data_*` tables actually have rows for the relevant facility/org name or slug (see the grouping-column caution in section 3 — the join key isn't always what you'd guess from the column name).

### 3. How to add a new indicator

Use `StatinsIndicator` (`app/models/dr_rai/statins_indicator.rb`, added in `commit 5c9a3729`) or `BpFudgingIndicator` (`app/models/dr_rai/bp_fudging_indicator.rb`, added in `commit d45eb6a8`) as your template — they're the two most recently added and represent the "SQL-backed" pattern that most new indicators will follow, as opposed to `ContactOverduePatientsIndicator`, which reuses the pre-existing `Reports::RegionSummary` pipeline and has no `DrRai::Data`/query factory of its own.

**3.1 Decide: does this indicator need its own data table?**

- If the numbers you need already exist in the general reporting pipeline (`Reports::RegionSummary`/`RegionSummaryAggregator`), you don't need a new table or query factory — follow `ContactOverduePatientsIndicator`'s pattern and call `quarterlies(region)` (inherited from the base `Indicator` class) from your `datasource` method.
- Otherwise (a genuinely new SQL query, typically against raw tables like `blood_pressures` or `prescription_drugs` rather than the `reporting_*` rollups), you need a new `DrRai::Data::*` model and a new `DrRai::QueryFactory` subclass — this is the path this section documents.

**3.2 Add the migration and `DrRai::Data` model**

1. Create a migration for a new `dr_rai_data_<name>` table (namespaced under `DrRai::Data`, whose `table_name_prefix` is `dr_rai_data_`). Include whatever grouping/period columns you need plus a unique index on the combination that identifies "one row" (e.g. `[month_date, facility_name]` for Titration, `[state, district, slug, quarter]` for BP Fudging) — `DrRai::DataService`'s upsert path (`ON CONFLICT`) depends on that index existing.
2. Create `app/models/dr_rai/data/<name>.rb`:
   ```ruby
   class DrRai::Data::<Name> < ApplicationRecord
     include DrRai::Chartable

     default_scope { where(<period_column>: <some reasonable trailing window>) }
     scope :insert_window, ->(timeline) { where(<period_column>: timeline) }

     chartable_internal_keys :<numerator_col>, :<denominator_col>
     chartable_period_key :<period_column>
     chartable_outer_grouping :<grouping_column>
   end
   ```
   `chartable_outer_grouping` is the column your indicator's `datasource(region)` will look values up by — decide up front whether that's `region.name` or `region.slug`, because the three existing tables are inconsistent and it's easy to copy the wrong one:

   | Table | Grouping column | What it actually contains | Looked up by |
   |---|---|---|---|
   | `dr_rai_data_titrations` | `facility_name` | facility name | `region.name` |
   | `dr_rai_data_bp_fudgings` | `slug` | actually the facility **name** (see the SQL: `reporting_facilities.facility_name as "slug"`), not a real slug | `region.name` |
   | `dr_rai_data_statins` | `aggregate_root` | facility slug *or* organization slug, unioned together | `region.name`, falling back to `region.slug` if the first lookup misses (see `StatinsIndicator#datasource`) |

   Don't trust the column name — check what's actually selected into it in the query factory before wiring up your indicator's `datasource`.

**3.3 Add the query factory**

1. Create `app/queries/dr_rai/<name>_query_factory.rb`, subclassing `DrRai::QueryFactory`, implementing `inserter` (plain insert) and `updater` (insert with `ON CONFLICT DO UPDATE` on your unique index).
2. Register it in `DrRai::QueryFactory.for` (`app/queries/dr_rai/query_factory.rb`) by adding an `elsif klazz <= Data::<Name>` branch — this is the one and only "registration" step the query layer needs.
3. Add a rake task in `lib/tasks/dr_rai.rake` following the existing three, and add its name to the array in `config/schedule.rb`'s nightly cron block so it actually runs.

**3.4 Add the indicator model**

Create `app/models/dr_rai/<name>_indicator.rb`, subclassing `DrRai::Indicator`, implementing:

- `datasource(region)` — memoize `YourData.chartable` (the region-independent part), then look the region up by whichever key you chose in 3.2 (see `TitrationIndicator`/`StatinsIndicator`/`BpFudgingIndicator` for the exact pattern). Be careful what you memoize: `TitrationIndicator`/`StatinsIndicator#is_supported?` and `Indicator#has_action_plans?` all use `@is_supported ||=` / `@region_exists ||=` with no key on the `region` argument, so a single indicator instance queried against two different regions will silently return the first region's answer for the second. This is only safe today because `Dashboard::DrRaiReport#custom_indicators` builds a fresh `DrRai::Indicator.all` (fresh instances) per request. Don't memoize anything that varies with `region` unless you key the memo on the region.
- `display_name` — plain string shown in the UI. There is no i18n/translation layer for indicator names today — `display_name`, `unit`, `action_passive`, `action_active` are all hardcoded English strings referenced directly in `dr_rai_report.html.erb`. If this deployment needs localized indicator names, that's new work, not a pattern to follow.
- `target_type_frontend` — one of `"percent"`, `"numeric"`, `"boolean"`, `"custom"` (matches `DrRai::Target::TYPES` keys). This determines which `DrRai::Target` subclass gets created when a facility staff member first sets a target for this indicator (see `ActionPlansController#hydrate_plan`).
- `numerator_key(all: nil)` / `denominator_key(all: nil)` — symbols identifying which of your `chartable_internal_keys` are the numerator/denominator. The `all:` parameter only matters if you want a "including non-contactable patients" toggle like `ContactOverduePatientsIndicator` has; for a straightforward indicator, ignore it and return the same key regardless.
- `unit`, `action_passive`, `action_active` — short English strings used to build the UI copy (e.g. "127 overdue patients", "call them").
- `is_supported?(region)` — return `true`/`false` for whether this indicator applies to this region. Use this for any per-country or per-region-type gating your indicator needs (see the `TitrationIndicator` per-country `case` statement) — this is a plain Ruby method, not a Flipper flag, so gating logic here has no UI and no toggle; it's a code change and redeploy to adjust.

**3.5 Attach a target type**

Pick the `DrRai::Target` subclass that matches `target_type_frontend`:

- `"percent"` / `PercentageTarget` — for indicators expressed as a percentage of a denominator (most of the existing ones — Contact Overdue, Titration, Statins).
- `"numeric"` / `NumericTarget` — for a raw count target rather than a percentage.
- `"boolean"` / `BooleanTarget` — for a yes/no "did we do this" target; the only target type with a working `achieved_for?`.
- `"custom"` / `CustomTarget` — for indicators that don't fit numerator/denominator percent semantics, like BP Fudging (a ratio where *lower* is better, not "percent of a goal reached"). If you use `"custom"`, you'll likely also need to add indicator-specific branches in `DrRai::ActionPlan` (see `current_ratio`/`previous_ratio`/`is_better?`, all currently BP-Fudging-specific behind `custom_target?`) and in the view template (`dr_rai_report.html.erb`) rather than getting a working UI for free — BP Fudging required real UI changes (`commit e0f64348`) beyond just picking `"custom"`.

Note that `achieved_for?` is unimplemented (raises) on every target type except Boolean. Nothing in the current UI calls it — progress is computed via `ActionPlan#progress` (`numerator.to_f / denominator * 100`) instead. Don't assume you need to implement `achieved_for?` to ship a new indicator; only do so if you're adding a new caller that needs it.

**3.6 Create the indicator row**

There is no seed file or registry array to update. Once your class exists, create exactly one row in a Rails console (in whichever environment you're enabling the feature):

```ruby
DrRai::YourNewIndicator.create!
```

`DrRai::Indicator.all` (used by `Dashboard::DrRaiReport#custom_indicators`) will then include it automatically for any region where `is_supported?` returns `true`. The `validates :type, uniqueness: true` on `Indicator` will raise if you accidentally create a second row of the same subclass.

**3.7 Feature-flagging**

There is no per-indicator Flipper flag mechanism — `dr_rai_reports` gates the whole report block, not individual indicators. If you need to roll out a new indicator gradually independent of the rest of Dr. Rai, `is_supported?(region)` (3.4) is your only lever today; you'd need to add new logic there (e.g. checking a new flag with the region as actor, since `Region` includes `Flipperable`) rather than relying on an existing mechanism.

**3.8 Tests**

Model specs live in `spec/models/dr_rai/`, one file per indicator (e.g. `spec/models/dr_rai/bp_fudging_indicator_spec.rb`, `spec/models/dr_rai/contact_overdue_patients_indicator_spec.rb`). Use `bp_fudging_indicator_spec.rb` as your template for a new SQL-backed indicator — it covers the "ui copy" methods (`display_name`, `target_type_frontend`, `numerator_key`, `denominator_key`, `action_passive`, `action_active`, `unit`) as simple value assertions, plus one test that the `datasource` method delegates to the `Data` model's `chartable` method. `spec/models/dr_rai/data/` has one spec per `DrRai::Data::*` model (e.g. `bp_fudging_spec.rb`) — add one there too. Query factory behavior is covered in `spec/queries/dr_rai/query_factory_spec.rb`, which currently only asserts the `for` dispatch table; add your new `elsif` branch to that spec. `spec/factories/dr_rai.rb` has factories for `:target` and `:indicator` (currently only a `:contact_overdue_patients` trait) and `:action_plan` — add a trait for your new indicator type there if specs need to build one.

**3.9 UI changes**

For a "percent" or "numeric" or "boolean" target type, no changes to `dr_rai_report.html.erb` or `dr_rai.scss` should be required — the existing markup is generic over `display_name`/`unit`/`action_passive`/`action_active`/numerator/denominator. For a `"custom"` target type (or any indicator whose progress isn't a simple numerator/denominator percentage), expect to touch both `app/components/dashboard/dr_rai_report.html.erb` and `app/assets/stylesheets/dr_rai.scss`, following what `commit e0f64348 ("New BP Fudging Design")` did for BP Fudging. There are no translation keys involved anywhere in this component (see 3.4) — any new copy is a hardcoded string in the indicator model or the `.erb` template.
