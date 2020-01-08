module AdminsPages
  class Show < ApplicationPage

    def verify_permission(value)

      within(:css, "div.card-row > ul") do
        value.each do |val|
          page.has_content?(val)
        end
      end
    end
  end
end
