class Drug < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "drugs"

  CREATED_TIME ||= File.ctime("config/data/drugs.yml").in_time_zone("UTC")
  UPDATED_TIME ||= File.mtime("config/data/drugs.yml").in_time_zone("UTC")

  def updated_at
    UPDATED_TIME
  end

  def created_at
    CREATED_TIME
  end

  def deleted_at
    if deleted == true
      UPDATED_TIME
    end
  end
end
