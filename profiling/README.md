# Profiling

The performance tests are designed to hit the APIs using the [Vegeta utility](https://github.com/tsenart/vegeta)

## Running the performance test
There's a template file called [sync_to_user.example](./sync_to_user.example) which defines how you can specify the APIs that need to be hit as a part of the performance test. The credentials are all crossed-out.

Copy it over to a new file called [sync_to_user](./sync_to_user) via,

```
make gen-requests for=sync_to_user
```

Configure the headers and body parameters appropriately.

The performance test itself can be run as follows:

```
make plot request=sync_to_user duration=20 rate=1
```

This will run the test at the breakneck speed of 1 request per second for 20 seconds and open up (this will only work on OS X) a latency report page for you.

## Raw metrics
```
make show-last
make show-last-json # requires `jq` to be installed
```
This will show a more detailed histogram on the console for the last request you ran.


## Add performance tests

More performance tests can be added by simply creating another template file in this directory, for eg.; `sync_from_user.example`. Make sure you cross-out all the sensitive credentials.
