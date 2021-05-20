class CreateFunctionMonthsSince < ActiveRecord::Migration[5.2]
  def up
    connection.execute("
      CREATE OR REPLACE FUNCTION months_since(from_date timestamp, to_date timestamp) RETURNS integer AS $$
      BEGIN

      RETURN
      (DATE_PART('year', to_date) - DATE_PART('year', from_date)) * 12 +
      (DATE_PART('month', to_date) - DATE_PART('month', from_date));

      END;
      $$ LANGUAGE plpgsql;
    ")
  end

  def down
    connection.execute("DROP FUNCTION months_since;")
  end
end
