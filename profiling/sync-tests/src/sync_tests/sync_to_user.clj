(ns sync-tests.sync-to-user
  (:require [clojure.core.async :as async]
            [clojure.data.csv :as csv]
            [clojure.edn :as edn]
            [clojure.java.io :as io]
            [clojure.java.io :as io]
            [jsonista.core :as j]
            [sync-tests.api :as api]
            [sync-tests.env :as env]
            [sync-tests.utils :as u]
            [taoensso.timbre :as log]))

(def ^:private csv-results (atom []))

(def ^:private users
  (-> "sync_to_user.edn"
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
   :prescription_drugs "/api/v3/prescription_drugs/sync"})

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
          result  {resource {:total-elapsed-ms 0.0 :record-count 0}}]
     (let [resource-path                    (get resources resource)
           {:keys [response start elapsed]} (u/timing #(deref (api/request resource-path options)))
           body                             (try (j/read-value (:body response))
                                                 (catch com.fasterxml.jackson.databind.exc.MismatchedInputException e
                                                   (log/info response)))
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

(defn ->csv []
  (with-open [writer (io/writer (format "%s_results.csv" (quot (System/currentTimeMillis) 1000)))]
    (csv/write-csv writer (into [["User ID" "Total time taken" "Results"]] @csv-results))))

(defn shutdown-hook []
  (.addShutdownHook (Runtime/getRuntime)
                    (Thread. (fn []
                               (println "Shutting down...")
                               (println "Dumping CSV report...")
                               (->csv)))))

(defn across-users []
  (shutdown-hook)

  (let [selected-users (take (:num-users @env/config) users)
        user-count  (count selected-users)
        result-chan (async/chan user-count)]

    (doall (map
            (fn [user]
              (async/go
                (let [{:keys [response elapsed]} (u/timing #(resources-sync user))]
                  (async/>! result-chan {:id (:id user) :time elapsed :result response}))))
            selected-users))

    (loop [users-read 0]
      (if (= users-read user-count)
        (log/info "Finished all requests for all users!")
        (do
          (let [data (async/<!! result-chan)]
            (swap! csv-results conj (vec [(:id data) (:time data) (:result data)]))
            (log/info data)
            (recur (inc users-read))))))))
