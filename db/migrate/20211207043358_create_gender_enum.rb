class CreateGenderEnum < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE gender_enum AS ENUM ('female', 'male', 'transgender');
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE TYPE gender_enum;
    SQL
  end
end
