pipeline {
  agent any

  stages {
    stage('Environment check') {
      steps {
        sh 'python3 --version'
      }
    }

    stage('Test') {
      steps {
        sh 'python3 -m unittest -v test_app.py'
      }
    }

    stage('Package') {
      steps {
        sh 'tar -czf python-app-${BUILD_NUMBER}.tar.gz app.py test_app.py'
        archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
      }
    }
  }
}
