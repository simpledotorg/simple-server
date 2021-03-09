#### Developing with the Android app

To run [simple-android](https://github.com/simpledotorg/simple-android/) app with the server running locally, you can
use [ngrok](https://ngrok.com).

```bash
brew cask install ngrok
ngrok http 3000
```

Then run the following with the HTTPS tunnel URL ngrok gives you:

```
export SIMPLE_SERVER_HOST=46fabf14a3d8.ngrok.io
export SIMPLE_SERVER_HOST_PROTOCOL=https
```

Now you can start your server and will use the forwarding address for your local API server:

```
rails server
```

The output of the ngrok command is HTTP and HTTPS URLs that can be used to access your local server. The HTTP URL cannot
be used since HTTP traffic will not be supported by the emulator. Configure the following places with the HTTPS URL.

In the `gradle.properties` file in the `simple-android` repository,
```
qaManifestEndpoint=<HTTPS URL>
```

In the `.env.development.local` (you can create this file if it doesn't exist),
```
SIMPLE_SERVER_HOST=<HTTPS URL>
SIMPLE_SERVER_HOST_PROTOCOL=https
```


### Gotchas

The android app caches _a lot_ of local data once you get logged in. It can be difficult to figure out how to refresh that data,
which can be very confusing when working on views like the progress tab (which is served by `/api/v3/user_analytics`).

If you are syncing too often, ngrok will start to throttle you!

