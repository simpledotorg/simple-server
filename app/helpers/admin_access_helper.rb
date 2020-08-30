module AdminAccessHelper
  def access_fraction(name, available, total)
    "#{available} #{"facility".pluralize(available)}"

    # currently unused, we may revive this later based on discussions with Claudio
    # - kit
    #
    # if available == total
    #   "#{total} #{name.pluralize(total)}"
    # else
    #   "#{available} / #{total} #{name.pluralize}"
    # end
  end

  def access_checkbox(form, name, resource, page: :new, checked_fn: -> { false })
    return access_resource_label(resource) if page.eql?(:show)

    opts = {
      id: resource.id,
      class: "access-input",
      label: resource.name.to_s,
      checked: page.eql?(:edit) && checked_fn.call
    }

    form.check_box("#{name.to_s}[]", opts, resource.id, nil)
  end

  def access_resource_label(resource)
    content_tag(:div, class: "form-check") do
      label_tag(resource.name.to_s, resource.name.to_s, class: "form-check-label")
    end
  end
end
