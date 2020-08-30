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

  def access_checkbox(form, name, resource, page: :edit, checked_fn: -> { false })
    opts = {
      id: resource.id,
      class: "access-input",
      label: resource.name.to_s,
      checked: page.eql?(:edit) && checked_fn.call
    }

    form.check_box("#{name.to_s}[]", opts, resource.id, nil)
  end
end
