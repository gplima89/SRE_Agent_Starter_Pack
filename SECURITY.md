# Security Policy

Do not open public issues containing credentials, private workload configuration,
customer logs, incident details, or exploits against a live customer environment.
No kit version is currently certified for production deployment.

Use GitHub private vulnerability reporting when the repository owner has enabled
it. If unavailable, request a private reporting channel without disclosing the
finding publicly. The maintainer must establish that channel before a release.
For Microsoft product issues use [MSRC](https://msrc.microsoft.com/report/vulnerability).
Include affected revision, sanitized reproduction, impact, and mitigation.

If a secret is exposed, revoke/rotate it immediately, notify its owner, review
access logs, then coordinate Git history cleanup. Deleting a file does not revoke
a credential. Ignored exports/state can still contain sensitive material.

Never remove approval, scope, confirmation, or secret-handling controls to make
tests pass. Security regression tests must accompany changes to those controls.