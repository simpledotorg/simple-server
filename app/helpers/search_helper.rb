# frozen_string_literal: true

module SearchHelper
  def search_query
    params[:search_query]
  end

  def searching?
    search_query.present?
  end

  def search_entries_info(records)
    info = page_entries_info(records, entry_name: "result".pluralize(records.length))
    info += " for '#{search_query}'" if search_query.present?
    info
  end
end
