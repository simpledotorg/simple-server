class DrugStocksQuery
  include Memery

  CACHE_VERSION = 1

  def initialize(facilities:, for_end_of_month:)
    @facilities = Facility.where(id: facilities)
    set_facility_group
    set_blocks
    @for_end_of_month = for_end_of_month
    @protocol = @facility_group.protocol
    @district = @facility_group.region
    @state = @facility_group.state
    @latest_drug_stocks = DrugStock.latest_for_facilities(@facilities, @for_end_of_month)
  end

  attr_reader :for_end_of_month, :facilities, :blocks, :facility_group

  def drug_stocks_report
    {total_patient_count: district_patient_count,
     total_drugs_in_stock: total_drugs_in_stock,
     total_patient_days: total_patient_days,

     district_patient_count: district_patient_count,
     district_patient_days: district_patient_days,
     district_drugs_in_stock: district_drugs_in_stock,

     facilities_total_patient_count: facilities_total_patient_count,
     facilities_total_patient_days: facilities_total_patient_days,
     facilities_total_drugs_in_stock: facilities_total_drugs_in_stock,

     patient_count_by_facility_id: patient_count_by_facility_id,
     patient_days_by_facility_id: patient_days_by_facility_id,
     drugs_in_stock_by_facility_id: drugs_in_stock_by_facility_id,

     patient_count_by_block_id: patient_count_by_block_id,
     patient_days_by_block_id: patient_days_by_block_id,
     drugs_in_stock_by_block_id: drugs_in_stock_by_block_id,
     last_updated_at: Time.now}
  end

  def drug_consumption_report
    Rails.cache.fetch(drug_consumption_cache_key,
      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
      force: RequestStore.store[:bust_cache]) do
      {total_patient_count: district_patient_count,
       total_drug_consumption: total_drug_consumption,

       district_patient_count: district_patient_count,
       district_drug_consumption: district_drug_consumption,

       facilities_total_patient_count: facilities_total_patient_count,
       facilities_total_drug_consumption: facilities_total_drug_consumption,

       patient_count_by_facility_id: patient_count_by_facility_id,
       drug_consumption_by_facility_id: drug_consumption_by_facility_id,

       patient_count_by_block_id: patient_count_by_block_id,
       drug_consumption_by_block_id: drug_consumption_by_block_id,
       last_updated_at: Time.now}.compact
    end
  end

  memoize def drugs
    @protocol.protocol_drugs.where(stock_tracked: true).load
  end

  memoize def protocol_drugs_by_category
    drugs_by_category = drugs
      .sort_by(&:sort_key)
      .group_by(&:drug_category)

    custom_drug_category_order = CountryConfig.current.fetch(:custom_drug_category_order, [])

    if custom_drug_category_order.to_set == drugs_by_category.keys.to_set
      drugs_by_category.sort_by { |drug_category, _| custom_drug_category_order.find_index(drug_category) }.to_h
    else
      drugs_by_category.sort_by { |drug_category, _| drug_category }.to_h
    end
  end

  memoize def drug_categories
    drugs.pluck(:drug_category).uniq
  end

  memoize def repository
    Reports::Repository.new(Region.where(source: [*@facilities, @facility_group]), periods: Period.month(@for_end_of_month))
  end

  memoize def patient_count_by_facility_id
    period = Period.month(@for_end_of_month)

    @facilities.with_region_information.each_with_object(Hash.new(0)) do |facility, result|
      result[facility.id] =
        repository.cumulative_assigned_patients.dig(facility.facility_region_slug, period).to_i -
        repository.ltfu.dig(facility.facility_region_slug, period).to_i
    end
  end

  memoize def patient_count_by_block_id
    @facilities.with_region_information.each_with_object(Hash.new(0)) do |facility, result|
      result[facility.block_region_id] += patient_count_by_facility_id[facility.id]
    end
  end

  memoize def district_patient_count
    period = Period.month(@for_end_of_month)

    repository.cumulative_assigned_patients.dig(@district.slug, period).to_i -
      repository.ltfu.dig(@district.slug, period).to_i
  end

  memoize def facilities_total_patient_count
    patient_count_by_facility_id.values.sum
  end

  memoize def selected_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@facilities, @for_end_of_month)
      .with_region_information
      .load
  end

  memoize def previous_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@facilities, end_of_previous_month)
      .with_region_information
      .load
  end

  memoize def district_selected_month_drug_stocks
    DrugStock.latest_for_regions_cte(@district, @for_end_of_month).load
  end

  memoize def district_previous_month_drug_stocks
    DrugStock.latest_for_regions_cte(@district, end_of_previous_month).load
  end

  memoize def district_facilities_selected_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@district.facilities, @for_end_of_month)
      .with_region_information
      .load
  end

  memoize def district_facilities_previous_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@district.facilities, end_of_previous_month)
      .with_region_information
      .load
  end

  memoize def facilities_total_drugs_in_stock
    selected_month_drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  memoize def district_drugs_in_stock
    district_selected_month_drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  memoize def district_facilities_total_drugs_in_stock
    district_facilities_selected_month_drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  memoize def total_drugs_in_stock
    district_drugs_in_stock.merge(district_facilities_total_drugs_in_stock) do |_, district_stock, facilities_stock|
      district_stock + facilities_stock
    end
  end

  memoize def drugs_in_stock_by_facility_id
    selected_month_drug_stocks.group(:facility_id, "protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  memoize def drugs_in_stock_by_block_id
    selected_month_drug_stocks
      .group("block_regions.id", "protocol_drugs.rxnorm_code")
      .sum(:in_stock)
  end

  def total_patient_days
    drug_categories.each_with_object({}) do |drug_category, result|
      result[drug_category] = category_patient_days(
        drug_category,
        (district_facilities_selected_month_drug_stocks + district_selected_month_drug_stocks),
        district_patient_count || 0
      )
    end
  end

  def district_patient_days
    drug_categories.each_with_object({}) do |drug_category, result|
      result[drug_category] = category_patient_days(
        drug_category,
        district_selected_month_drug_stocks,
        district_patient_count || 0
      )
    end
  end

  def patient_days_by_facility_id
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {}
      result[facility_id][drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id },
        patient_count_by_facility_id[facility_id] || 0
      )
    end
  end

  def patient_days_by_block_id
    @blocks.pluck(:id).product(drug_categories).each_with_object({}) do |(block_id, drug_category), result|
      result[block_id] ||= {}
      result[block_id][drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id },
        patient_count_by_block_id[block_id] || 0
      )
    end
  end

  def facilities_total_patient_days
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks,
        facilities_total_patient_count
      )
    end
  end

  def category_patient_days(drug_category, category_drug_stocks, patient_count)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol_drugs: drugs,
      drug_category: drug_category,
      current_drug_stocks: category_drug_stocks,
      patient_count: patient_count
    ).patient_days
  end

  def drug_consumption_by_facility_id
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {}
      result[facility_id][drug_category] =
        category_drug_consumption(
          drug_category,
          selected_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id },
          previous_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id }
        )
    end
  end

  def drug_consumption_by_block_id
    @blocks.pluck(:id).product(drug_categories).each_with_object({}) do |(block_id, drug_category), result|
      result[block_id] ||= {}
      result[block_id][drug_category] =
        category_drug_consumption(
          drug_category,
          selected_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id },
          previous_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id }
        )
    end
  end

  def facilities_total_drug_consumption
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_drug_consumption(
        drug_category,
        selected_month_drug_stocks,
        previous_month_drug_stocks
      )
    end
  end

  def district_drug_consumption
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_drug_consumption(
        drug_category,
        district_selected_month_drug_stocks,
        district_previous_month_drug_stocks
      )
    end
  end

  def total_drug_consumption
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_drug_consumption(
        drug_category,
        (district_selected_month_drug_stocks + district_facilities_selected_month_drug_stocks),
        (district_previous_month_drug_stocks + district_facilities_previous_month_drug_stocks)
      )
    end
  end

  def category_drug_consumption(drug_category, current_drug_stocks, previous_drug_stocks)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol_drugs: drugs,
      drug_category: drug_category,
      current_drug_stocks: current_drug_stocks,
      previous_drug_stocks: previous_drug_stocks
    ).consumption
  end

  memoize def end_of_previous_month
    (@for_end_of_month - 1.month).end_of_month
  end

  def drug_stocks_cache_key
    [
      "#{self.class.name}#drug_stocks",
      @facilities.map(&:id).sort,
      @latest_drug_stocks.cache_key,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end

  def drug_consumption_cache_key
    [
      "#{self.class.name}#drug_consumption",
      @facilities.map(&:id).sort,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end

  private

  def set_facility_group
    facility_group_ids = @facilities.pluck(:facility_group_id).uniq
    raise "All facilities should belong to the same facility group." if facility_group_ids.count > 1
    @facility_group = FacilityGroup.find(facility_group_ids.first)
  end

  def set_blocks
    @blocks =
      Region
        .block_regions
        .joins("INNER JOIN regions facility_region ON regions.path @> facility_region.path")
        .where(facility_region: {source_id: @facilities})
        .distinct("regions.id")
  end
end
