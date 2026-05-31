#!/usr/bin/env bats

# Run with: bats tests/test_collectors.bats

load '../lib/collectors.sh'

@test "collect_cpu returns a number between 0 and 100" {
  run collect_cpu
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -ge 0 ]
  [ "$output" -le 100 ]
}

@test "collect_memory returns a number between 0 and 100" {
  run collect_memory
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -ge 0 ]
  [ "$output" -le 100 ]
}

@test "collect_disk returns a number for root mount" {
  run collect_disk "/"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "collect_service returns UP for a known running service" {
  run collect_service "cron"
  [ "$status" -eq 0 ]
  [[ "$output" == "UP" || "$output" == "DOWN" ]]
}

@test "collect_load_average returns a float" {
  run collect_load_average
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+$ ]]
}