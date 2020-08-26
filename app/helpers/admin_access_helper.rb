module AdminAccessHelper
  def access_fraction(name, available, total)
    if available == total
      "#{total} #{name}"
    else
      "#{available} / #{total} #{name}"
    end
  end

  def access_checkbox(form, name, resource, op: :new, checked: false)
    if op.eql?(:view)
      content_tag(:div, class: "form-check") do
        label_tag(resource.name.to_s, resource.name.to_s, class: "form-check-label")
      end
    else
      opts = {
        id: resource.id,
        class: "access-input",
        label: resource.name.to_s,
        checked: op.eql?(:edit) && checked
      }

      form.check_box(name, opts, resource.id, nil)
    end
  end
end
