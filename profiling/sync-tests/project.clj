(defproject sync-tests "0.1.0"
  :description "sync-tests: simulate a parallel, global simple app that fires multiple requests"
  :url "https://github.com/simpledotorg/simple-server"
  :license {:name "The MIT License",
            :url "http://opensource.org/licenses/MIT"}
  :dependencies [[org.clojure/clojure "1.10.1"]
                 [http-kit "2.5.0"]
                 [com.cemerick/url "0.1.1"]
                 [metosin/jsonista "0.2.7"]
                 [org.clojure/core.async "1.3.610"]
                 [com.taoensso/timbre "5.1.0"]
                 [org.clojure/data.csv "1.0.0"]]
  :profiles {:uberjar {:aot :all}}
  :main ^:skip-aot sync-tests.core
  :repl-options {:init-ns sync-tests.core})
