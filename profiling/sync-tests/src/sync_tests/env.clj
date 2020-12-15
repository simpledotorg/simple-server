(ns sync-tests.env)

(def valids #{:dev :sbx :perf1 :perf2})
(def valid? (fn [env] (contains? valids env)))
(def config (atom {:name        :dev
                   :num-users   10
                   :req-limit   1000
                   :req-timeout (* 1 60 1000)}))
