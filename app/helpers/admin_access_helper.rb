module AdminAccessHelper
  def access_facility_count(available)
    "#{available} #{"facility".pluralize(available)}"
  end

  def access_checkbox(name, resource, page: :new, checked_fn: -> { false })
    case page
      when :show
        content_tag(:div, class: "form-check__show") { access_resource_label(resource) }
      when :new, :edit
        content_tag(:div, class: "form-check") do
          opts = {
            id: resource.id,
            class: "access-input form-check-input"
          }

          checked = page.eql?(:edit) && checked_fn.call
          checkbox = check_box_tag("#{name}[]", resource.id, checked, opts)
          label = access_resource_label(resource)

          concat([checkbox, label].join.html_safe)
        end
      else
        raise ArgumentError, "Unsupported page type: #{page}"
    end
  end

  def access_resource_label(resource)
    label_tag(resource.id, resource.name.to_s, class: "form-check-label")
  end

  def access_level_select(form, access_levels, page: :new, access_level: nil)
    form.select(:access_level,
      {},
      {label: "Access *"},
      {
        class: "access-levels",
        id: :access_level,
        disabled: page.eql?(:edit),
        required: page.eql?(:new)
      }) do
      access_levels.each do |level|
        access_level_option(level, access_level)
      end
    end
  end

  def access_level_option(level, current_access_level)
    tag =
      content_tag(:option,
        level[:id],
        value: level[:id],
        class: :show,
        selected: level[:id].to_s.eql?(current_access_level),
        data: {content: access_level_option_data(level)})

    concat(tag)
  end

  def access_level_option_data(level)
    option = <<-HTML.strip_heredoc
        <div class="access-level-item-data">
          <span class="title">
             #{level[:name]}
          </span>
          <span class="description"> #{level[:description]}</span>
        </div>
    HTML

    sanitize(option)
  end
end
