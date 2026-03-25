module AssetsHelper
  def csp_nonce_attributes
    nonce = respond_to?(:content_security_policy_nonce) ? content_security_policy_nonce : nil
    nonce.present? ? {nonce: nonce} : {}
  end

  def inline_file(asset_name)
    if (asset = Rails.application.assets&.find_asset(asset_name))
      asset.source.html_safe
    else
      asset_path = Rails.application.assets_manifest.assets[asset_name]
      File.read(File.join(Rails.root, "public", "assets", asset_path)).html_safe
    end
  end

  def inline_js(asset_name)
    content_tag(:script, inline_file(asset_name), {type: "text/javascript"}.merge(csp_nonce_attributes))
  end

  def inline_stylesheet(asset_name)
    content_tag(:style, inline_file(asset_name), {type: "text/css"}.merge(csp_nonce_attributes))
  end

  def inline_svg(asset_name, classname: "svg-container")
    content_tag(:div, inline_file(asset_name), class: classname)
  end
end
