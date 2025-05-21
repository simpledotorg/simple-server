This document provides a guide on how to whitelabel your application

## Environment Variables

Set the following environment variables according to your desired branding:

- `APPLICATION_BRAND_NAME` – The new brand name which will be reflected throughout the application.
- `TEAM_EMAIL_ID` – Email address for your team contact.
- `HELP_EMAIL_ID` – Help center support email.
- `CVHO_EMAIL_ID` – Email address for your CVHO team.
- `ENG_EMAIL_ID` – Contact email for the engineering team.
- `FAVICON_URL` - Public URL for accessing the favicon.
- `WHITELABEL_APP` - Set to TRUE/FALSE to deteremine whether you are using a whitelabelled version of the app or not. Look and feel of the dashboard will change based on this flag
- `DEPLOYMENT_CHECKLIST_LINK` - Link to the deployment checklist document, which would appear under Resources tab in the dashboard
- `PRIVACY_LINK` - Link to the privacy policy adhereing to the new brand
- `LICENSE_LINK` - Link to the license information adhereing to the new brand

### Example Configuration

```bash
APPLICATION_BRAND_NAME="Demo"
TEAM_EMAIL_ID="team_email@test.org"
HELP_EMAIL_ID="help_email@test.org"
CVHO_EMAIL_ID="cvho_email@test.org"
ENG_EMAIL_ID="eng-backend@test.org"
FAVICON_URL="https://www.google.com/favicon.ico"
DEPLOYMENT_CHECKLIST_LINK="https://docs.google.com/document/d/1qLoXo3dIw7A2WIRqsJ5Zx77DJDYnNnfu76vm8PVobxU/edit?usp=sharing"
WHITELABEL_APP="TRUE"
PRIVACY_LINK="https://www.simple.org/privacy"
LICENSE_LINK="https://www.simple.org/license/"
```

Make sure these environment variables are set in your environment, `.env` file, or your deployment configuration system.

Once set, the application will reflect the customized brand name and email addresses in relevant views, exports, headers, and documentation like Swagger API pages.
