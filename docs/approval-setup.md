# Where to configure approvals in GitHub

For each repository:
1. Open the repository.
2. Go to **Settings**.
3. Click **Environments**.
4. Click the environment name, for example **Staging**.
5. Under **Deployment protection rules**, click **Required reviewers**.
6. Add the users or teams that must approve deployments.
7. Save the environment.

Recommended mapping:
- Lab -> no required reviewers
- Development -> optional or no approval
- Test -> optional or no approval
- Staging -> 1 required reviewer from `platform-admins`
- Production Commercial -> required reviewers from `commercial-customers` and `platform-admins`
- Production Government -> required reviewers from `government-customers` and `identity-security`
- Destroy -> required reviewers from `platform-admins`

Also recommended:
- Turn on **Prevent self-review** for `Production Commercial`, `Production Government`, and `Destroy`.
- Restrict deployment branches for production environments to `main`.
