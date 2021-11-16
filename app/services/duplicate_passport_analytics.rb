class DuplicatePassportAnalytics
  require "squid"
  class << self
    prepend SentryHandler
  end
  include Memery
  include ApplicationHelper

  IDENTIFIER_TYPES = %w[simple_bp_passport]
  DEFAULT_REPORTABLE_METRICS = {
    across_facilities: :duplicate_passports_across_facilities,
    same_facility: :duplicate_passports_in_same_facility,
    across_districts: :duplicate_passports_across_districts,
    across_blocks: :duplicate_passports_across_blocks
  }

  # for continuously reporting metrics in an automated way
  def self.call
    new.report
  end

  # for finding out the trend of changes of dupes across time (until now) for the specified metric(s)
  # it builds a pdf of the trends and emails it to the specified power_user email
  def self.trend(metrics: :all, since: 4.months.ago, step: 2.weeks, send_to_power_user: nil)
    default_reportable_keys = DEFAULT_REPORTABLE_METRICS.keys

    metrics =
      if metrics.eql?(:all)
        default_reportable_keys
      else
        metrics.map(&:to_sym)
      end

    raise ArgumentError, "Unknown metrics." unless (default_reportable_keys & metrics) == metrics

    new(report_email: send_to_power_user).trend(metrics, since, step)
  end

  attr_reader :report_email

  def initialize(report_email: nil)
    @report_email = report_email
  end

  def report
    DEFAULT_REPORTABLE_METRICS.values.each do |fn_name|
      dupe_count = public_send(fn_name).size
      log "#{fn_name} are #{dupe_count}"
      gauge "#{fn_name}.size", dupe_count
    end

    legacy_report
  end

  # legacy reporting to avoid breaking existing dashboards
  def legacy_report
    Rails.logger.tagged("ReportDuplicatePassports") do
      Rails.logger.info msg: "#{duplicate_passports_across_facilities.size} passports have duplicate patients across facilities"
    end

    Statsd.instance.gauge("ReportDuplicatePassports.size", duplicate_passports_across_facilities.size)
  end

  def trend(metrics, since, step)
    return unless report_email_is_power_user?

    metrics
      .to_h { |name| make_trend(name, since, step) }
      .then { |data| make_chart(data) }
      .then { |data| send_email(data) }
  end

  memoize def duplicate_passports_across_facilities(until_date = Time.current)
    PatientBusinessIdentifier
      .where.not(identifier: "")
      .where(identifier_type: IDENTIFIER_TYPES)
      .where("created_at <= ?", until_date)
      .group(:identifier)
      .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .pluck(:identifier)
  end

  memoize def duplicate_passports_in_same_facility(until_date = Time.current)
    PatientBusinessIdentifier
      .where.not(identifier: "")
      .where(identifier_type: IDENTIFIER_TYPES)
      .where("created_at <= ?", until_date)
      .group(:identifier)
      .having("COUNT(DISTINCT #{passport_assigning_facility}) = 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .pluck(:identifier)
  end

  memoize def duplicate_passports_across_districts(until_date = Time.current)
    PatientBusinessIdentifier
      .where.not(identifier: "")
      .where(identifier_type: IDENTIFIER_TYPES)
      .where("patient_business_identifiers.created_at <= ?", until_date)
      .joins("INNER JOIN regions facility_region ON facility_region.source_id = #{passport_assigning_facility}::uuid")
      .joins("INNER JOIN regions district_region ON district_region.path @> facility_region.path and district_region.region_type = 'district'")
      .group(:identifier)
      .having("COUNT(DISTINCT district_region.id) > 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
      .pluck(:identifier)
  end

  memoize def duplicate_passports_across_blocks(until_date = Time.current)
    PatientBusinessIdentifier
      .where.not(identifier: "")
      .where(identifier_type: IDENTIFIER_TYPES)
      .where("patient_business_identifiers.created_at <= ?", until_date)
      .joins("INNER JOIN regions facility_region ON facility_region.source_id = #{passport_assigning_facility}::uuid")
      .joins("INNER JOIN regions block_region ON block_region.path @> facility_region.path and block_region.region_type = 'block'")
      .group(:identifier)
      .having("COUNT(DISTINCT block_region.id) > 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
      .pluck(:identifier)
  end

  # this method isn't used for any automated reporting since it performs poorly
  # it can be run manually to collect data in an ad-hoc way
  memoize def duplicate_passports_without_next_appointments(until_date = Time.current)
    duplicate_passports_across_facilities(until_date).select do |identifier|
      dupe_patients =
        Patient
          .includes(:latest_scheduled_appointments)
          .where(id: PatientBusinessIdentifier.where(identifier: identifier).pluck(:patient_id))

      dupe_patients.any? { |p| p&.latest_scheduled_appointment.blank? }
    end
  end

  # this method isn't used for any automated reporting
  #
  # it's primarily used to find dupes using a best guess algorithm
  # and to be scanned by humans manually (humans are better)
  memoize def duplicate_passports_with_actually_different_patients(until_date = Time.current)
    duplicate_passports_across_facilities(until_date).select do |identifier|
      dupe_patients =
        Patient
          .where(id: PatientBusinessIdentifier.where(identifier: identifier).pluck(:patient_id))

      name_combos = dupe_patients.pluck(:full_name).combination(2)
      find_age_thru_name_fn = ->(name) { dupe_patients.find { |p| p.full_name == name }&.age }

      name_combos.any? do |p1_name, p2_name|
        age1 = find_age_thru_name_fn.call(p1_name)
        age2 = find_age_thru_name_fn.call(p2_name)
        error_margin_in_name = [p1_name.size, p2_name.size].max / 2.0

        if levenshtein_distance(p1_name, p2_name) > error_margin_in_name
          age1 && age2 ? age1 != age2 : true
        elsif age1 && age2
          age1 != age2
        else
          false
        end
      end
    end
  end

  private

  def passport_assigning_facility
    # use ->> to fetch data as text so we can coerce as uuid or keep as text easily
    "COALESCE((metadata->>'assigning_facility_id'), (metadata->>'assigningFacilityUuid'))"
  end

  def make_trend(metric, since, step)
    metric_fn = DEFAULT_REPORTABLE_METRICS.dig(metric)
    return {} if metric_fn.blank?
    now = Time.current

    log "Building trend for #{metric}..."
    for_time_series(since, now, step)
      .to_h { |time| [display_date(time), public_send(metric_fn, time).size] }
      .then { |timeseries| [metric, timeseries] }
  end

  def make_chart(data)
    metric_names = data.keys
    chart_opts = {
      border: true,
      steps: 2,
      legend: {right: 50, bottom: 50},
      labels: [true, true] # https://github.com/Fullscreen/squid/pull/57#issuecomment-327988967
    }
    rand_color = -> { "%06x" % (rand * 0xffffff) }
    metrics_per_page = 2 # slicing by 2 ensures we can start a new page before we run out

    log "Rendering chart for #{metric_names.join(",")}..."
    Prawn::Document
      .new {
        text "Duplicate passports across different dimensions\n\n\n"

        metric_names.each_slice(metrics_per_page) do |batch|
          batch.each do |metric|
            chart({metric => data[metric]}, chart_opts.merge(colors: [rand_color.call])) # new chart for every metric
          end

          start_new_page
        end
      }.render
  end

  def send_email(chart)
    log "Sending email to power user: #{report_email}..."

    email_params = {
      to: report_email,
      subject: "BP Passport Analytics [#{display_date(Time.current)}]",
      content_type: "multipart/mixed", # to allow both a body and an attachment
      body: "Please find enclosed."
    }

    mailer = ApplicationMailer.new
    email = mailer.mail(email_params)
    email.attachments["bp-passport-analytics.pdf"] = {
      mime_type: "application/pdf",
      content: chart
    }
    email.deliver
  end

  def log(msg)
    Rails.logger.tagged(self.class.name) { Rails.logger.info msg: msg }
  end

  def gauge(stat, value)
    Statsd.instance.gauge("#{self.class.name}.#{stat}", value)
  end

  # rubygems implements levenshtein_distance for guessing typos, we can reuse it
  # source: https://github.com/rubygems/rubygems/blob/master/lib/rubygems/text.rb
  def levenshtein_distance(s, t)
    require "rubygems/text"
    Class.new.extend(Gem::Text).levenshtein_distance(s, t)
  end

  def for_time_series(start_t, end_t, step)
    start_t_sec = start_t.to_datetime.to_i
    end_t_sec = end_t.to_datetime.to_i

    Enumerator.new do |yielder|
      (start_t_sec..end_t_sec).step(step) do |date|
        yielder << Time.at(date)
      end

      # add the end date explicitly anyway
      yielder << Time.at(end_t_sec)
    end
  end

  def report_email_is_power_user?
    return if report_email.blank?
    email_authentication = EmailAuthentication.find_by(email: report_email)
    return if email_authentication.blank?

    email_authentication.user.power_user?
  end
end
