module AdminAccessHelper
  def access_fraction(name, available, total)
    "#{available} / #{total} #{name}"
  end

  def access_checkbox(form, name, resource)
    form.check_box(name, {id: resource.id, class: 'access-input', label: "#{resource.name}"})
  end
end
