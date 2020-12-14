(ns sync-tests.sync-to-user
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]
            [jsonista.core :as j]
            [sync-tests.api :as api]
            [sync-tests.utils :as u]))

(def sync-results (atom {}))
(def env (atom :dev))
(def ^:private users (-> "sync_to_user.edn" io/resource slurp edn/read-string :users))
(def ^:private resources {:facilities "/api/v3/facilities/sync"
                          :protocols "/api/v3/protocols/sync"
                          :patients "/api/v3/patients/sync"
                          :medical_histories "/api/v3/medical_histories/sync"
                          :appointments "/api/v3/blood_pressures/sync"
                          :blood_sugars "/api/v4/blood_sugars/sync"
                          :blood_pressures "/api/v3/blood_pressures/sync"
                          :precription_drugs "/api/v3/prescription_drugs/sync"})
(def ^:private limit 500)

(defn headers [{:keys [id facility-id access-token sync-region-id] :as user}]
  {"X-FACILITY-ID" facility-id
   "X-USER-ID"     id
   "Authorization" (apply str ["Bearer" " " access-token])})

(defn init-req-options [user]
  {:headers      (headers user)
   :query-params {:limit limit :process_token nil}})

(defn sync-resource
  ([resource user]
   (prn resource)
   (loop [options (init-req-options user)
          result  {resource {:total-elapsed-ms 0.0, :record-count 0}}]
     (let [req                    (u/timing #(deref (api/request @env (get resources resource) options)))
           response               (:result req)
           time-taken             (:elapsed req)
           body                   (j/read-value (:body response))
           records                (get body (name resource))
           response-process-token (get body "process_token")
           updated-result         (-> result
                                      (update-in [resource :record-count] + (count records))
                                      (update-in [resource :total-elapsed-ms] + time-taken))]
       (if (< (count records) limit)
         updated-result
         (recur (assoc-in options
                          [:query-params :process_token]
                          response-process-token)
                updated-result))))))

(defn sync-resources [user]
  (doall (map #(sync-resource %1 user) (keys resources))))
