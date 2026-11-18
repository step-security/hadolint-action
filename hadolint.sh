#!/bin/bash

# validate subscription status
REPO_PRIVATE=$(jq -r '.repository.private | tostring' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
UPSTREAM="hadolint/hadolint-action"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
  fi
fi

# The problem-matcher definition must be present in the repository
# checkout (outside the Docker container running hadolint). We copy
# problem-matcher.json to the home folder.

PROBLEM_MATCHER_FILE="/problem-matcher.json"
if [ -f "$PROBLEM_MATCHER_FILE" ]; then
  cp "$PROBLEM_MATCHER_FILE" "$HOME/"
fi
# After the run has finished we remove the problem-matcher.json from
# the repository so we don't leave the checkout dirty. We also remove
# the matcher so it won't take effect in later steps.
# shellcheck disable=SC2317
cleanup() {
  echo "::remove-matcher owner=step-security/hadolint-action::"
}
trap cleanup EXIT

echo "::add-matcher::$HOME/problem-matcher.json"

config_args=()
if [ -n "$HADOLINT_CONFIG" ]; then
  config_args=(-c "$HADOLINT_CONFIG")
fi

if [ -z "$HADOLINT_TRUSTED_REGISTRIES" ]; then
  unset HADOLINT_TRUSTED_REGISTRIES
fi

# The inputs are never passed through eval. Word splitting and globbing of the
# dockerfile input are kept (so values such as "*Dockerfile" keep working),
# but shell metacharacters in it are not interpreted.
if [ "$HADOLINT_RECURSIVE" = "true" ]; then
  shopt -s globstar

  filename="${!#}"
  extra_args=("${@:1:$#-1}")

  old_ifs=$IFS
  IFS=
  # shellcheck disable=SC2206
  files=(**/$filename)
  IFS=$old_ifs

  RESULTS=$(hadolint "${config_args[@]}" "${extra_args[@]}" -- "${files[@]}")
else
  flags=$*
  # shellcheck disable=SC2086
  RESULTS=$(hadolint "${config_args[@]}" $flags)
fi
FAILED=$?

if [ -n "$HADOLINT_OUTPUT" ]; then
  if [ -f "$HADOLINT_OUTPUT" ]; then
    HADOLINT_OUTPUT="$TMP_FOLDER/$HADOLINT_OUTPUT"
  fi

  # Refuse to write over the runner's file-command files (GITHUB_ENV,
  # GITHUB_PATH, GITHUB_OUTPUT, ...) or the workflow metadata.
  OUTPUT_REAL=$(realpath -m -- "$HADOLINT_OUTPUT")
  case "$OUTPUT_REAL" in
    /github/file_commands | /github/file_commands/* | /github/workflow | /github/workflow/*)
      echo "::error::output-file must not point to the runner's internal files: $HADOLINT_OUTPUT"
      exit 1
      ;;
  esac
  for runner_file in "$GITHUB_ENV" "$GITHUB_PATH" "$GITHUB_OUTPUT" "$GITHUB_STATE" "$GITHUB_STEP_SUMMARY"; do
    if [ -n "$runner_file" ] && [ "$OUTPUT_REAL" = "$(realpath -m -- "$runner_file")" ]; then
      echo "::error::output-file must not point to the runner's internal files: $HADOLINT_OUTPUT"
      exit 1
    fi
  done

  printf '%s\n' "$RESULTS" >"$HADOLINT_OUTPUT"
fi

RESULTS="${RESULTS//$'\\n'/''}"

# Random delimiter so that the results can never close the heredoc-style
# block early and inject further entries into GITHUB_OUTPUT / GITHUB_ENV.
DELIMITER="HADOLINT_EOF_$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$RANDOM$RANDOM$$")"

{
  echo "results<<$DELIMITER"
  printf '%s\n' "$RESULTS"
  echo "$DELIMITER"
} >>"$GITHUB_OUTPUT"

{
  echo "HADOLINT_RESULTS<<$DELIMITER"
  printf '%s\n' "$RESULTS"
  echo "$DELIMITER"
} >>"$GITHUB_ENV"

[ -z "$HADOLINT_OUTPUT" ] || echo "Hadolint output saved to: $HADOLINT_OUTPUT"

exit $FAILED
