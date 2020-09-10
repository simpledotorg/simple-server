module AdminAccessHelper
  def access_facility_count(available)
    "#{available} #{"facility".pluralize(available)}"
  end

  def access_checkbox(form, name, resource, page: :new, checked_fn: -> { false })
    return access_resource_label(resource) if page.eql?(:show)

    opts = {
      id: resource.id,
      class: "access-input",
      label: resource.name.to_s,
      checked: page.eql?(:edit) && checked_fn.call
    }

    form.check_box("#{name}[]", opts, resource.id, nil)
  end

  def access_resource_label(resource)
    content_tag(:div, class: "form-check__show") do
      label_tag(resource.name.to_s, resource.name.to_s, class: "form-check-label")
    end
  end

  def access_level_select(form, available_access_levels, page: :new, disabled: false, current_access_level: nil)
    form.select(:access_level,
      {},
      {label: "Access *"},
      {
        class: "access-levels",
        id: :access_level,
        disabled: disabled,
        required: page.eql?(:new)
      }) do
      available_access_levels.each do |level|
        access_level_option(level, current_access_level)
      end
    end
  end

  def access_level_option(level, current_access_level)
    tag =
      content_tag(:option,
        level[:id],
        value: level[:id],
        class: "show",
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
