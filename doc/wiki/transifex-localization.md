# Transifex Localization

# GPI and Transifex

We work with a contractor called GPI, they do translations for us. Translations are done on a platform called
[Transifex](https://transifex.com). Transifex automatically pulls in our locale files from our Github repository, and
GPI enters translations in there. When the translations are completed, Transifex automatically opens PRs against our
repo with the changes to our locale files. GPI works in batches, so we get a burst of PRs every month or two.

# Handling Transifex PRs

When a batch of pull requests come in:

### 1. Let them sit for a couple of days before you do anything

GPI usually makes tweaks for a while, so it's best to let the dust settle before attempting to merge

### 2. Rebase all the transfix PRs against a new branch (eg. `translations-batch-mm-yyyy`)

This allows us to avoid a slew of Semaphore test builds that must all pass in succession before the PRs can be shipped.

### 3. Check and fix all top-level language keys

Due to limitations of the Transifex-Github plugin, Transifex PRs will attempt to change the top-level keys of the YML
locale files. Check and correct all of them to ensure that the top-level key is _not_ changed by the PR.

More details:

> Transifex lets you customize the filenames for our locale files, but does not let you customize the top-level locale
> keys inside the locale files. The standard transifex keys are underscored.
>
> Can we switch the locale keys to snake-case then? Not easily. That locale key has to match whatever the app requests,
> and the app requests hyphenated keys today. If we were to change that behavior, we’d still have a period where we’ll
> have to support both, to support older app versions. We could maintain two sets of files/keys for a while, but if a
> translation came in during this time, we’d have to manually copy the translation to both files. Seems like it may not
> be worth the effort to make our keys consistent with Transifex's expectations.

### 4. Approve messages

Whatsapp messages sent to patients require prior approval by Whatsapp before we can send them. If the translations add
or update any Whatsapp messages, you must upload the new templates to Twilio and get Whatsapp approval for them prior
to shipping the translations.

#### How to apply for Whatsapp approval on Twilio
- Create a new message template from https://www.twilio.com/console/sms/whatsapp/templates.
- Give the template a recognisable name. Do add a date to the template name (ex. 2021_06_22_missed_visit_reminder).
- If you're adding Missed visit reminders, pick `Appointment Update` as the template's category.
- Add the English message as the first message. You will need to replace dynamic content in the message strings. For ex. `%{facility_name}` becomes `{{1}}`.
- Add the rest of the languages as translations in the same template.

### 5. Test the changes

Take the translations for a spin in app to check for content length, character escaping, etc.

### 6. Ship

# Resources

* [Simple Server Transifex dashboard](https://www.transifex.com/vital-strategies/simple-server/dashboard/)
* [Example batch of Transifex translations](https://github.com/simpledotorg/simple-server/pull/2512)
* [#localisation Slack channel](https://simpledotorg.slack.com/archives/CG4EUB944)
