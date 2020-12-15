(ns sync-tests.core
  (:require [clojure.java.io :as io]
            [sync-tests.env :as env]
            [sync-tests.sync-to-user :as stu]
            [taoensso.timbre :as log]
            [taoensso.timbre.appenders.core :as appenders]))

(def log-file-name "log.txt")
(io/delete-file log-file-name :quiet)
(log/merge-config!{:appenders {:spit (appenders/spit-appender {:fname log-file-name})}})
(log/set-level! :debug)

(defn -main [& args]
  ;; lein run <env> <test> <num-users>
  ;; lein run dev sync-to-user 1
  (let [[env-name test-name num-users] args
        num-users-int (swap! env/config assoc :num-users (Integer/parseInt num-users))
        env (keyword env-name)]

    (if (env/valid? env)
      (swap! env/config assoc :name env)
      (throw (java.lang.IllegalArgumentException.
              (format "Enter a valid env name. Valid env names: '%s'", env/valids))))

    (case test-name
      "sync-to-user" (do
                       (log/info "Starting a run for sync-to-user..")
                       (log/info @env/config)
                       (stu/across-users))
      (throw (java.lang.IllegalArgumentException.
              (format "Don't know how to run test: '%s'. Enter a valid test name.", test-name))))))
