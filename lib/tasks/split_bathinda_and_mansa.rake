require "tasks/scripts/split_bathinda_and_mansa"

task split_bathinda_and_mansa: :environment do
  SplitBathindaAndMansa.call
end
