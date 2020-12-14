(ns sync-tests.utils)

(defn now []
  (.getTime (java.util.Date.)))

(defn timing [body-fn]
  (let [start (now)
        result (body-fn)]
    {:elapsed (- (now) start)
     :result result}))
