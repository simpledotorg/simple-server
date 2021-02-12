drug_stock_config = YAML.load_file("config/data/drug_stock_config.yml")

Rails.application.config.drug_stock_config = drug_stock_config.with_indifferent_access
