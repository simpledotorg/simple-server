# [DEPRECATED] Production Deployment

1. Ensure changelog is up to date
    - Do a commit log diff against the previous version, ensure all the important changes are in the upcoming release
    - Keep a blank upcoming release
    - Verify changelog with other teams

2. Tag release
    - Create a tag off master with the same name as in the changelog. Typically with the format: yyyy-mm-dd-n.
    - Add a short description in the tag for the release
    - `git tag -a <yyyy-mm-dd-n> -m "<description>"`
    - `git push --tags`

3. Understand migrations to be run as a part of this release
    - `git diff <previous-tag>..<current-tag> db/migrate`
    - lookout for data migrations, and irreversible migrations

Perform the following steps on staging.

4. If there is a data migration
    - Check for changes in lib: `git diff -w 2018-08-13-1..2018-09-17-1 lib/`
    - Run the migration locally with the prod data to ensure it succeeds
    - Make a backup of the production DB before doing the data migration
    - What to do if there is a data migration?
      - Sometimes, data migrations can be run after the deploy, and sometimes they need to be run before.
      - The `cap deploy` script does a code deploy, runs schema migrations, and starts the service.
      - If data migrations need to be run before, ensure `cap deploy` does not start the service before that.  

5. Setup configs, and feature flags
    - Find out what config has changed since the last release
    - `git diff -w <previous-tag>..<current-tag> .env.development`
    - Verify ansible vault has all the required keys and values
    - Run ansible deploy from [deployment repository](https://github.com/simpledotorg/deployment) to ensure config is updated
    - `ansible-playbook -v  --vault-id ~/Projects/resolve/secrets/password_file deploy.yml -i hosts.<env>`

6. Prepare for potential downtime
    - Figure out the right time of the day during which downtime is acceptable
    - Inform stakeholders of this downtime, and ensure this is alright.
    - Announce deployment and downtime on slack in advance, and when deploying

7. Deploy the tag
    - Deploy the current tag to the env
    - `BRANCH=2018-09-17-1 bundle exec cap <env> deploy`  

8. Run any required data migration rake tasks

9. [FOR CRITICAL RELEASES] Do an end-to-end QA of the app, and surgically remove the data created
    - Go over QA flows to smoke test vital flows
    - Go over the newly added features/flows to ensure things are smooth
    - How to test: https://docs.google.com/document/d/1QC5_bWYeKAlFFbzTsLozUiq8Vuk1-3s4s3Ixzz3LcLw/edit#

10. Monitor the service
    - Monitor vitals, rails logs, nginx logs, and dashboards

Repeat steps 4 to 10 on the production environment if everything went well on staging.
