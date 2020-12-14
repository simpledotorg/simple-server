(ns sync-tests.api
  (:require [org.httpkit.client :as http]
            [cemerick.url :refer (url url-encode)]))

(defonce ^:private base-url
  {:sandbox "https://api-sandbox.simple.org"
   :dev "http://simple.test"})

(defn request [env path options]
  (http/get (str (url (get base-url env) path)) options))
