# How to setup a new OAuth Application for integrating with Simple

Currently, we need to create OAuth Applications for users that want to send us data through the `/import` API.

Since our partner organizations are trusted machine clients in this case, we create and send them a client ID and secret
that is used for the client credential flow needed for the import API. We also create a machine user associated with these
organizations.

To create a machine user and an OAuth application, run the following:

# TODO fix this
```shell
bundle exec cap <env> deploy:rake task='setup_oauth_application[<name>,<org_id>,<client_id>,<client_secret (optional)>]'
```

Note the client ID and client secret of the OAuth application in the output. This should be shared with the partner organizations.
