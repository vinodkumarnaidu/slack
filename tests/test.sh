#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export PS4='$ '
if [ ! -d ".git" ]; then
  echo 'ERROR: must be run from the root of the repository.  e.g.'
  echo './tests/test.sh'
  exit 1
fi
echo 'Last command to exit has the non-zero exit status.'
set -x

bash -n ./tests/random_port.sh
test -x ./tests/random_port.sh
export RANDOM_PORT="$(./tests/random_port.sh)"
bash -n ./slack_bootstrap.sh
test -x ./slack_bootstrap.sh
export JENKINS_START="java -jar jenkins.war --httpPort=${RANDOM_PORT} --httpListenAddress=127.0.0.1"
export JENKINS_WEB="http://127.0.0.1:${RANDOM_PORT}"
export JENKINS_CLI="java -jar ./jenkins-cli.jar -s http://127.0.0.1:${RANDOM_PORT} -noKeyAuth"
export JENKINS_HOME="$(mktemp -d ../my_jenkins_homeXXX)"
bash -xe ./slack_bootstrap.sh
source scripts/common.sh
auth_set_curl
csrf_set_curl
${CURL} -s "${JENKINS_WEB}/api/json?pretty=true" | python ./tests/api_test.py
test -e jenkins.pid
./scripts/provision_jenkins.sh stop
test ! -e jenkins.pid
test -e console.log
test -e jenkins.war
test -e "${JENKINS_HOME}"
test -e plugins
gradle clean
test ! -e console.log
test ! -e jenkins.war
test ! -e "${JENKINS_HOME}"
test ! -e plugins
