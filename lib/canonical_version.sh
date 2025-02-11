#!/usr/bin/env bash

output_section() {
  local title="$1"
  echo "-----> $title"
}

erlang_builds_url() {
  case "${STACK}" in
    "heroku-20")
      erlang_builds_url="https://builds.hex.pm/builds/otp/ubuntu-20.04"
      ;;
    "heroku-22")
      erlang_builds_url="https://builds.hex.pm/builds/otp/ubuntu-22.04"
      ;;
    *)
      erlang_builds_url="https://s3.amazonaws.com/heroku-buildpack-elixir/erlang/cedar-14"
      ;;
  esac
  echo $erlang_builds_url
}

fetch_erlang_versions() {
  output_section "Stack selected: ${STACK:-default}"
  output_section "Fetching available Erlang versions..."
  
  case "${STACK}" in
    "heroku-20")
      url="https://builds.hex.pm/builds/otp/ubuntu-20.04/builds.txt"
      output_section "Using Ubuntu 20.04 Erlang builds"
      curl -s "$url" | awk '/^OTP-([0-9.]+ )/ {print substr($1,5)}'
      ;;
    "heroku-22")
      url="https://builds.hex.pm/builds/otp/ubuntu-22.04/builds.txt"
      output_section "Using Ubuntu 22.04 Erlang builds"
      curl -s "$url" | awk '/^OTP-([0-9.]+ )/ {print substr($1,5)}'
      ;;
    *)
      url="https://raw.githubusercontent.com/HashNuke/heroku-buildpack-elixir-otp-builds/master/otp-versions"
      output_section "Using HashNuke's cedar-14 Erlang builds"
      curl -s "$url"
      ;;
  esac
}

exact_erlang_version_available() {
  # TODO: fallback to hashnuke one if not ubuntu-20.04 and not found on hex
  version=$1
  available_versions=$2
  found=1
  while read -r line; do
    if [ "$line" = "$version" ]; then
      found=0
    fi
  done <<< "$available_versions"
  echo $found
}

exact_elixir_version_available() {
  version=$1
  available_versions=$2
  found=1
  while read -r line; do
    if [ "$line" = "$version" ]; then
      found=0
    fi
  done <<< "$available_versions"
  echo $found
}

check_erlang_version() {
  version=$1
  output_section "Checking Erlang version: $version"
  
  echo "Available versions:"
  fetch_erlang_versions | while read -r line; do
    echo "       $line"
  done
  
  exists=$(exact_erlang_version_available "$version" "$(fetch_erlang_versions)")
  if [ $exists -ne 0 ]; then
    output_line "Sorry, Erlang '$version' isn't supported yet or isn't formatted correctly. For a list of supported versions, please see https://github.com/HashNuke/heroku-buildpack-elixir#version-support"
    exit 1
  fi
  
  output_section "Erlang version $version is available"
}

check_elixir_version() {
  version=$1
  exists=$(exact_elixir_version_available "$version" "$(fetch_elixir_versions)")
  if [ $exists -ne 0 ]; then
    output_line "Sorry, Elixir '$version' isn't supported yet or isn't formatted correctly. For a list of supported versions, please see https://github.com/HashNuke/heroku-buildpack-elixir#version-support"
    exit 1
  fi
}
