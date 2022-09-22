task :support_pg_extensions_in_heroku do
  # https://devcenter.heroku.com/changelog-items/2446
  next unless ENV["SIMPLE_SERVER_ENV"].in?(%w[android_review review])

  path = "db/structure.sql"
  f = File.open(path)
  contents = f.read.to_s
  f.close

  contents.gsub! "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;", "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA heroku_ext;"
  contents.gsub! "CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;", "CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA heroku_ext;"
  contents.gsub! "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;", "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA heroku_ext;"
  contents.gsub! "public.ltree", "heroku_ext.ltree"
  contents.gsub! "public.gen_random_uuid()", "heroku_ext.gen_random_uuid()"
  contents.gsub! "public.subpath", "heroku_ext.subpath"
  contents.gsub! "public.=", "heroku_ext.="

  IO.write(path, contents)
end
