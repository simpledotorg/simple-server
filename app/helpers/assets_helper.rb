module AssetsHelper
  def inline_file(path)
    if assets = Rails.application.assets
      asset = assets.find_asset(path)
      return '' unless asset
      asset.source
    else
      File.read(File.join(Rails.root, 'public', asset_path(path)))
    end
  end

  def inline_js(path)
    content_tag(:script, inline_file(path), type: "text/javascript")
  end
end
