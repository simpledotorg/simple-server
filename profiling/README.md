# Profiling

The performance tests are designed to hit the APIs using the [Vegeta utility](https://github.com/tsenart/vegeta)

## Running the perf test
The [sync_to_user](./sync_to_user) file contains the GET APIs that would be hit as part of the performance test. The headers and body parameters can also be configured in here.

The perf test itself can be run as follows:
```
make plot request=sync_to_user duration=20 rate=1
```
This will run the perf test at the breakneck speed of 1 request per second for 20 seconds and open up (this will only work on OS X) a latency report page for you.

## Raw metrics
```
make show-last
make show-last-json # requires `jq` to be installed
```
This will show a more detailed histogram on the console for the last request you ran.
