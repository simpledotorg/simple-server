module AdminAccessHelper
  def access_fraction(name, available, total)
    if available == total
      "#{total} #{name}"
    else
      "#{available} / #{total} #{name}"
    end
  end

  def access_checkbox(form, name, resource, op: :new, checked: false)
    opts = {
      id: resource.id,
      class: "access-input",
      label: resource.name.to_s,
      hidden: op.eql?(:view),
      checked: op.eql?(:edit) && checked
    }

    form.check_box(name, opts, resource.id, nil)
  end
end
