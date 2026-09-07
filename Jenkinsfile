pipeline {
  agent any

environment {
  PATH = "/Users/akahlawa/.rd/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
}
  stages {
    stage('Environment check') {
      steps {
        sh 'python3 --version'
        sh 'docker version'
      }
    }

    stage('Python unit test') {
      steps {
        sh 'python3 -m unittest -v test_app.py'
      }
    }

    stage('Docker build') {
      steps {
        sh 'docker build -t jenkins-python-demo:${BUILD_NUMBER} .'
      }
    }

    stage('Docker test') {
      steps {
        sh 'docker run --rm jenkins-python-demo:${BUILD_NUMBER}'
      }
    }

    stage('Package') {
      steps {
        sh 'tar -czf python-app-${BUILD_NUMBER}.tar.gz app.py test_app.py Dockerfile'
        archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
      }
    }
  }
}
