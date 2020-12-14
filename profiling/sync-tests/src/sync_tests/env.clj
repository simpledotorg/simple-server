(ns sync-tests.env)

(def valids #{:dev :sbx :perf1 :perf2})
(def valid? (fn [env] (contains? valids env)))
(def नाम (atom :dev))
