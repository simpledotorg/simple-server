## Use SRI to improve cross domain security

From https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity:
> Subresource Integrity (SRI) is a security feature that enables browsers to verify that resources they fetch (for example, from a CDN) are delivered without unexpected manipulation. It works by allowing you to provide a cryptographic hash that a fetched resource must match.

### How to enable integrity checks

When copying sources from CDNs, look for the integrity check hash, or an option to copy HTML with SRI.
A link with SRI should look lik this:
```html
<script 
        src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js" 
        integrity="sha256-+8RZJua0aEWg+QVVKg4LEzEEm/8RFez5Tb4JBNiV5xA=" 
        crossorigin="anonymous"
></script>
```

### Notes
- Google fonts generates different assets based on the browser, so it's not possible to add SRI: Documentation: Explain why we don't support Subresource Integrity [google/fonts#473](https://github.com/google/fonts/issues/473)
- The asset for redoc is generated server side, and the asset is also dynamic: https://www.jsdelivr.com/using-sri-with-dynamic-files