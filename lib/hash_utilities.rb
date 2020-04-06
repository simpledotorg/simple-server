module HashUtilities
  def autovivified_hash
    Hash.new {|l, k| l[k] = Hash.new(&l.default_proc)}
  end
end
