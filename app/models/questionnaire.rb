class Questionnaire < ApplicationRecord
  scope :for_sync, -> { with_discarded }

  def localize_layout(sub_layout = layout)
    sub_layout
      .then { |l| localize_text(l) }
      .then { |l| localize_items_recursively(l) }
  end

  private

  def localize_text(sub_layout)
    text = sub_layout["text"]
    return sub_layout unless text

    sub_layout.merge({"text" => I18n.t(text)})
  end

  def localize_items_recursively(sub_layout)
    items = sub_layout["item"]
    return sub_layout unless items

    sub_layout.merge({"item" => items.map { |item| localize_layout(item) }})
  end
end
