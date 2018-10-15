#!/usr/bin/env groovy

pipeline {
  agent { label 'ubuntu' }
  environment {
    MAILTRAP_USER = '510e25a65c0cc9'
    MAILTRAP_PASS = '29c15697ae5c53'
    NODE_VERSION = '8.9'
  }

  stages {
    stage('Clean') {
      agent { label 'jenkins' }

      steps {
        cancelJobs()
        notifySlack()
      }
    }

    stage('Setup') {
      steps {
        setupEnvironment()
        installDependencies()
      }
    }

    stage('Lint') {
      steps { lint() }
    }

    stage('Compile') {
      steps { compile() }
    }

    stage('Build Docker Image') {
      steps { buildDockerImage() }
    }

    stage('Test - Unit') {
      steps { runUnitTests() }

      post {
        always {
          junit "test_results/unit.xml"
        }
      }
    }

    stage('Test - Jobs') {
      steps { runJobTests() }

      post {
        always {
          junit "test_results/jobs.xml"
        }
      }
    }

    stage('Test - Acceptance (Legacy)') {
      steps { runLegacyAcceptanceTests() }

      post {
        always {
          junit "test_results/acceptance.xml"
        }
      }
    }

    stage('Test - Acceptance') {
      steps { runAcceptanceTests() }

      post {
        always {
          junit "test_results/acceptance-new.xml"
        }
      }
    }

    stage('Push Docker Image') {
      steps { pushDockerImage() }
    }

    stage('Deploy') {
      steps { deploy() }
    }
  }

  post {
    failure {
      notifySlack('FAILED')
    }

    success {
      notifySlack('SUCCESS')
    }

    unstable {
      notifySlack('UNSTABLE')
    }
  }
}

def buildDockerImage() {
  sh './scripts/docker-build.sh'
}

def cancelJobs() {
  def jobname = env.JOB_NAME
  def currentBuildNum = env.BUILD_NUMBER.toInteger()
  def job = Jenkins.instance.getItemByFullName(jobname)
  def cancel = false;

  for (build in job.builds) {
    def buildNum = build.getNumber().toInteger()

    if (!build.isBuilding()) {
      continue;
    }

    if (currentBuildNum < buildNum) {
      cancel = true;
    }

    if (currentBuildNum == buildNum && cancel) {
      println "cancel run, newer one queued";
      build.doStop();
      return;
    }

    if (currentBuildNum > buildNum && build.isBuilding()) {
      println('cancelling previous run');
      build.doStop();
      return;
    }
  }
}

def compile() {
  sh 'yarn compile'
}

def deploy() {
  if (isDevelop()) {
    return deployPreview()
  }

  if (isRelease()) {
    return deployStaging()
  }

  if (isMaster()) {
    return deployBeta()
  }

  noop()
}

def deployBeta() {
  sh '''
    echo "automating deploy via heroku"
    # git config url.ssh://git@heroku.com/.insteadOf https://git.heroku.com/
    # echo "deploying to beta"
    # environment=beta yarn deploy
  '''
}

def deployPreview() {
  parallel(
    api: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME api preview
      '''
    },
    worker: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME worker preview
      '''
    },
    scheduler: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME scheduler preview
      '''
    }
  )
}

def deployStaging() {
  parallel(
    api: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME api staging
      '''
    },
    worker: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME worker staging
      '''
    },
    scheduler: {
      sh '''
        export LATEST_COMMIT=$(git rev-parse --short HEAD)
        export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"
        ./scripts/kube-deploy.sh $TAG_NAME scheduler staging
      '''
    }
  )
}

def installDependencies() {
  sh '''
    yarn config set spin false
    yarn install
  '''
}

def installNode() {
  sh 'n "$NODE_VERSION"'
}

def isDevelop() {
  return (env.BRANCH_NAME == "develop")
}

def isMaster() {
  return (env.BRANCH_NAME == "master")
}

def isRelease() {
  return (env.BRANCH_NAME ==~ /release\/.*/)
}

def lint() {
  sh 'grunt ciLint'
}

def noop() {
  sh 'echo nothing to do, skipping'
}

def notifySlack(String buildStatus = 'STARTED') {
  // Build status of null means success.
  buildStatus = buildStatus ?: 'SUCCESS'

  def color

  if (buildStatus == 'STARTED') {
      color = '#318AFB'
  } else if (buildStatus == 'SUCCESS') {
      color = '#85C44F'
  } else if (buildStatus == 'UNSTABLE') {
      color = '#EDC130'
  } else {
      color = '#FC3B60'
  }

  def encodedJobName = env.JOB_NAME.replaceAll("%2F", "/")
  def msg = "${buildStatus}: `${encodedJobName}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

  slackSend(color: color, message: msg)
}

def outputEnvironment() {
  sh '''
    echo $PATH
    node --version
    yarn --version
  '''
}

def pushDockerImage() {
  sh '''
    export LATEST_COMMIT=$(git rev-parse --short HEAD)
    export TAG_NAME="$BRANCH_NAME-$LATEST_COMMIT"

    ./scripts/docker-publish.sh $TAG_NAME
  '''
}

def runAcceptanceTests() {
  sh 'docker-compose run --rm app-tests node_modules/.bin/grunt test-ci-acceptance-new || true'
}

def runJobTests() {
  sh 'docker-compose run --rm app-tests node_modules/.bin/grunt test-ci-jobs || true'
}

def runLegacyAcceptanceTests() {
  sh 'docker-compose run --rm app-tests node_modules/.bin/grunt test-ci-acceptance || true'
}

def runUnitTests() {
  sh 'docker-compose run --rm app-tests node_modules/.bin/grunt test-ci-unit || true'
}

def setupEnvironment() {
  installNode()
  outputEnvironment()
}
