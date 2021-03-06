#!/usr/bin/env bats

load test_helper

setup() {
  global_setup
}

teardown() {
  global_teardown
}

@test "(apps) apps:help" {
  run /bin/bash -c "dokku apps:help"
  echo "output: $output"
  echo "status: $status"
  assert_output_contains "Manage apps"
}

@test "(apps) apps:create" {
  run /bin/bash -c "dokku apps:create $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:list | grep $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_output $TEST_APP
  destroy_app

  run /bin/bash -c "dokku apps:create 1994testapp"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:create testapp:latest"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku apps:create testApp:latest"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku apps:create TestApp"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku --app $TEST_APP apps:create"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:list | grep $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_output $TEST_APP

  destroy_app
}

@test "(apps) app autocreate disabled" {
  run /bin/bash -c "dokku config:set --no-restart --global DOKKU_DISABLE_APP_AUTOCREATION='true'"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run deploy_app
  echo "output: $output"
  echo "status: $status"
  assert_failure
  run /bin/bash -c "dokku config:unset --no-restart --global DOKKU_DISABLE_APP_AUTOCREATION"
}

@test "(apps) apps:destroy" {
  create_app
  run /bin/bash -c "dokku --force apps:destroy $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  create_app
  run /bin/bash -c "dokku --force --app $TEST_APP apps:destroy"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:rename" {
  deploy_app
  run /bin/bash -c "dokku apps:rename $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:list | grep $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_output ""
  run /bin/bash -c "curl --silent --write-out '%{http_code}\n' `dokku url great-test-name` | grep 404"
  echo "output: $output"
  echo "status: $status"
  assert_output ""
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:create $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:rename $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:rename with tls" {
  setup_test_tls
  deploy_app
  run /bin/bash -c "dokku apps:rename $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:clone" {
  deploy_app
  run /bin/bash -c "dokku apps:clone $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:list | grep $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "curl --silent --write-out '%{http_code}\n' `dokku url great-test-name` | grep 404"
  echo "output: $output"
  echo "status: $status"
  assert_output ""
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:clone ssl-app" {
  run /bin/bash -c "dokku config:set --no-restart $TEST_APP DOKKU_PROXY_PORT_MAP=https:443:5000 DOKKU_PROXY_SSL_PORT=443"
  deploy_app
  run /bin/bash -c "dokku apps:clone $TEST_APP app-without-ssl"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku --quiet proxy:ports app-without-ssl | xargs"
  echo "output: $output"
  echo "status: $status"
  assert_output "http 80 5000"
  run /bin/bash -c "dokku config:get app-without-ssl DOKKU_PROXY_SSL_PORT"
  echo "output: $output"
  echo "status: $status"
  assert_output ""
  run /bin/bash -c "dokku --force apps:destroy app-without-ssl"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:clone --skip-deploy" {
  deploy_app
  run /bin/bash -c "dokku apps:clone --skip-deploy $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run [ -d /home/dokku/great-test-name/tls ]
  assert_failure
  run [ -f /home/dokku/great-test-name/URLS ]
  assert_failure
  run [ -f /home/dokku/great-test-name/VHOST ]
  assert_failure
  run /bin/bash -c "curl --silent --write-out '%{http_code}\n' `dokku url $TEST_APP` | grep 200"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "curl --silent --write-out '%{http_code}\n' `dokku url great-test-name` | grep 404"
  echo "output: $output"
  echo "status: $status"
  assert_failure
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "curl --silent --write-out '%{http_code}\n' `dokku url $TEST_APP` | grep 200"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:clone --ignore-existing" {
  deploy_app
  run /bin/bash -c "dokku apps:create great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku apps:clone --ignore-existing $TEST_APP great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
  run /bin/bash -c "dokku --force apps:destroy great-test-name"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(apps) apps:exists" {
  run /bin/bash -c "dokku apps:exists $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  create_app
  run /bin/bash -c "dokku apps:exists $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku --force apps:destroy $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

}

@test "(apps) apps:lock/locked/unlock" {
  create_app

  run /bin/bash -c "dokku apps:report $TEST_APP --locked"
  echo "output: $output"
  echo "status: $status"
  assert_output "false"

  run /bin/bash -c "dokku apps:locked $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku apps:lock $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:report $TEST_APP --locked"
  echo "output: $output"
  echo "status: $status"
  assert_output "true"

  run /bin/bash -c "dokku apps:locked $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:unlock $TEST_APP"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku apps:report $TEST_APP --locked"
  echo "output: $output"
  echo "status: $status"
  assert_output "false"

  destroy_app
}
