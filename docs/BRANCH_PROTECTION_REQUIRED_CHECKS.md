# Branch Protection Required Checks

Use the following status check names when configuring branch protection for `main`:

- `backend-ci`
- `flutter-ci`
- `functions-ci`

These names come from the CI job names in:

- `.github/workflows/backend-ci.yml`
- `.github/workflows/flutter-ci.yml`
- `.github/workflows/functions-ci.yml`

## Enforce Manually in GitHub

1. Open the repository on GitHub.
2. Go to **Settings** > **Branches**.
3. Create a new branch protection rule (or edit the existing one) for `main`.
4. Enable **Require a pull request before merging**.
5. Enable **Require status checks to pass before merging**.
6. Select these required checks:
   - `backend-ci`
   - `flutter-ci`
   - `functions-ci`
7. (Recommended) Enable **Require branches to be up to date before merging**.
8. Save the rule.

If CI job names change later, update this rule to match the new check names.
