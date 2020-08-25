module AdminAccessHelper
  def access_fraction(name, available, total)
    if available == total
      "#{total} #{name}"
    else
      "#{available} / #{total} #{name}"
    end
  end

  def access_checkbox(form, name, resource)
    form.check_box(name, { id: resource.id, class: 'access-input', label: resource.name.to_s })
  end
end
