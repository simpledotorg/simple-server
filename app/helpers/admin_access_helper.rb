# frozen_string_literal: true

module AdminAccessHelper
  def access_facility_count(available)
    "#{available} #{"facility".pluralize(available)}"
  end

  def access_checkbox(name, resource, parent_id:, checked: false)
    opts = {
      id: resource.id,
      class: "access-input form-check-input",
      "data-parent-id": parent_id
    }

    check_box_tag("#{name}[]", resource.id, checked, opts)
  end

  def access_resource_label(resource)
    label_tag(resource.id, resource.name.to_s, class: "form-check-label")
  end

  def access_level_select(form, access_levels, required: true, disabled: false, current_access_level: nil)
    form.select(:access_level,
      {},
      {label: "Access *"},
      {
        class: "access-level-wrapper",
        id: "access-level",
        disabled: disabled,
        required: required
      }) do
      access_levels.each do |level|
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

  def access_tree_load_error
    error_html = <<~ERROR.strip_heredoc.squish
      <p class='load-error-message'>
        There was an error, <a href=''> please try again </a>
      </p>
    ERROR

    sanitize(error_html)
  end
end
