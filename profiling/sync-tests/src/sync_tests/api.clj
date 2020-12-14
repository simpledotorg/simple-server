(ns sync-tests.api
  (:require [org.httpkit.client :as http]
            [cemerick.url :refer (url url-encode)]
            [sync-tests.env :as env]))

(defonce ^:private base-url
  {:dev   "http://simple.test"
   :sbx   "https://api-sandbox.simple.org"
   :perf1 "https://api-production-perf-1.simple.org"
   :perf2 "https://api-production-perf-2.simple.org"})

(defn request [path options]
  (http/get (-> base-url
                (get @env/नाम)
                (url path)
                str)
            options))
