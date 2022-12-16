class Questionnaire < ApplicationRecord
  scope :for_sync, -> { with_discarded }

  def with_localized_layout(sub_layout = layout)
    items = sub_layout["item"]
    return nil if items.nil?

    items.map do |item|
      item.merge({ "item" => with_localized_layout(item),
                   "text" => I18n.t(item["text"]) }.compact)
    end
  end
end
