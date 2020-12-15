(ns sync-tests.sync-to-user
  (:require [clojure.core.async :as async]
            [clojure.edn :as edn]
            [clojure.java.io :as io]
            [jsonista.core :as j]
            [sync-tests.api :as api]
            [sync-tests.utils :as u]
            [taoensso.timbre :as log]
            [sync-tests.env :as env]))

(def ^:private users
  (-> "sync_to_user.edn.sample"
      io/resource
      slurp
      edn/read-string
      :users))

(def ^:private resources
  {:facilities        "/api/v3/facilities/sync"
   :protocols         "/api/v3/protocols/sync"
   :patients          "/api/v3/patients/sync"
   :medical_histories "/api/v3/medical_histories/sync"
   :appointments      "/api/v3/blood_pressures/sync"
   :blood_sugars      "/api/v4/blood_sugars/sync"
   :blood_pressures   "/api/v3/blood_pressures/sync"
   :precription_drugs "/api/v3/prescription_drugs/sync"})

(defn headers [{:keys [id facility_id access_token sync_region_id] :as user}]
  {"X-FACILITY-ID"    facility_id
   "X-USER-ID"        id
   "X-SYNC-REGION-ID" sync_region_id
   "Authorization"    (apply str ["Bearer" " " access_token])})

(defn init-req-options [user]
  {:headers      (headers user)
   :timeout      (:req-timeout @env/config)
   :query-params {:limit (:req-limit @env/config) :process_token nil}})

(defn resource-sync
  ([resource user]
   (loop [options (init-req-options user)
          result  {resource {:total-elapsed-ms 0.0, :per-req-info [] :record-count 0}}]
     (let [resource-path                    (get resources resource)
           {:keys [response start elapsed]} (u/timing #(deref (api/request resource-path options)))
           body                             (j/read-value (:body response))
           records                          (get body (name resource))
           response-process-token           (get body "process_token")
           updated-result                   (-> result
                                                (update-in [resource :record-count] + (count records))
                                                (update-in [resource :total-elapsed-ms] + elapsed))]
       (if (< (count records)
              (:req-limit @env/config))
         updated-result
         (recur (assoc-in options
                          [:query-params :process_token]
                          response-process-token)
                updated-result))))))

(defn resources-sync [user]
  (doall (map #(resource-sync %1 user) (keys resources))))

(defn across-users []
  (let [user-count  (count users)
        result-chan (async/chan user-count)]
    (doall (map
            (fn [user]
              (async/go
                (let [{:keys [response elapsed]} (u/timing #(resources-sync user))]
                  (async/>! result-chan {(:id user) {:time   elapsed
                                                     :result response}}))))
            (take (:num-users @env/config)
                  users)))

    (loop [users-read 0]
      (if (= users-read user-count)
        (log/info "Finished all requests for all users!")
        (do
          (log/info (async/<!! result-chan))
          (recur (inc users-read)))))))
