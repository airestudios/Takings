# eBay marketplace account deletion endpoint

The serverless endpoint is located at `api/ebay-deletion.js`. Deploy this
repository as a Vercel project; the Flutter application and GitHub Pages site
do not need to move to Vercel.

## Vercel environment variables

Add these variables to the Production environment in Vercel Project Settings:

- `EBAY_DELETION_VERIFICATION_TOKEN`: the 32–80 character token entered in the
  eBay developer portal.
- `EBAY_DELETION_ENDPOINT`: the complete deployed endpoint URL, for example
  `https://takings-ebay.vercel.app/api/ebay-deletion`.

The value of `EBAY_DELETION_ENDPOINT` must exactly match the Notification
Endpoint URL entered in eBay. Do not add a trailing slash to one value unless
it is also present in the other.

After adding the variables, redeploy the Vercel Production deployment. Then
enter the endpoint URL and the same verification token in eBay's Marketplace
Account Deletion notification settings.

The endpoint answers eBay's GET validation challenge and acknowledges POST
deletion notifications. It deliberately does not log notification payloads.
