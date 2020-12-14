(ns sync-tests.core
  (:require [sync-tests.env :as env]
            [sync-tests.sync-to-user :as stu]))

(defn -main [& args]
  (let [[env-name test-name] args
        env (keyword env-name)]

    (if (env/valid? env)
      (reset! env/नाम env)
      (throw (java.lang.IllegalArgumentException.
              (format "Enter a valid env name. Valid env names: '%s'", env/valids))))

    (case test-name
      "sync-to-user" (do
                       (println "Starting a run for sync-to-user..")
                       (stu/across-users))
      (throw (java.lang.IllegalArgumentException.
              (format "Don't know how to run test: '%s'. Enter a valid test name.", test-name))))))
