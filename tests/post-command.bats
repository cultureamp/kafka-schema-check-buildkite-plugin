#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "Executes kafka schema check when command has successed" {
  # export BUILDKITE_PLUGIN_KAFKA_SCHEMA_CHECK_SCHEMA_NAMES[0]=["test.v1", "test.v2", "test.v3"]

  # run "$PWD/hooks/post-command"

  # assert_success
  # assert_output --partial ":5678: test.v1"
}
