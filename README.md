[![StepSecurity Maintained Action](https://raw.githubusercontent.com/step-security/maintained-actions-assets/main/assets/maintained-action-banner.png)](https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions)

# Hadolint Action

> GitHub Action that runs [Hadolint](https://github.com/hadolint/hadolint) Dockerfile linting tool.

[![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?style=for-the-badge)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/step-security/hadolint-action/ci.yml?branch=master&style=for-the-badge)](https://github.com/step-security/hadolint-action/action)


## Usage

Add the following step to your workflow configuration:

```yml
steps:
  - uses: actions/checkout@v7
  - uses: step-security/hadolint-action@v3
    with:
      dockerfile: Dockerfile
```

## Inputs

| Name                 | Description                                                                                                                             | Default            |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| `dockerfile`         | The path to the Dockerfile to be tested                                                                                                 | `./Dockerfile`     |
| `recursive`          | Search for specified dockerfile </br> recursively, from the project root                                                                | `false`            |
| `config`             | Custom path to a Hadolint config file                                                                                                   | `./.hadolint.yaml` |
| `output-file`        | A sub-path where to save the </br> output as a file to                                                                                  | `/dev/stdout`      |
| `no-color`           | Don't create colored output (`true`/`false`)                                                                                            | `false`            |
| `no-fail`            | Never fail the action (`true`/`false`)                                                                                                  | `false`            |
| `verbose`            | Output more information (`true`/`false`)                                                                                                | `false`            |
| `format`             | The output format. One of [`tty` \| `json` \| </br> `checkstyle` \| `codeclimate` \| </br> `gitlab_codeclimate` \| `codacy` \| `sarif`] | `tty`              |
| `failure-threshold`  | Rule severity threshold for pipeline </br> failure. One of [`error` \| `warning` \| </br>  `info` \| `style` \| `ignore`]               | `info`             |
| `override-error`     | Comma separated list of rules to treat with `error` severity                                                                            |                    |
| `override-warning`   | Comma separated list of rules to treat with `warning` severity                                                                          |                    |
| `override-info`      | Comma separated list of rules to treat with `info` severity                                                                             |                    |
| `override-style`     | Comma separated list of rules to treat with `style` severity                                                                            |                    |
| `ignore`             | Comma separated list of Hadolint rules to ignore.                                                                                       | <none>             |
| `trusted-registries` | Comma separated list of urls of trusted registries                                                                                      |                    |

## Output

The Action will store results in an environment variable that can be used in other steps in a workflow.

Example to create a comment in a PR:

```
- name: Update Pull Request
  uses: actions/github-script@v9
  if: github.event_name == 'pull_request'
  with:
    script: |
      const output = `
      #### Hadolint: \`${{ steps.hadolint.outcome }}\`
      \`\`\`
      ${process.env.HADOLINT_RESULTS}
      \`\`\`
      `;

      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      })
```

## Hadolint Configuration

To configure Hadolint (for example ignore rules), you can create an `.hadolint.yaml` file in the root of your repository. Please check the Hadolint [documentation](https://github.com/hadolint/hadolint#configure).

## 📝 License

[MIT](LICENSE)
