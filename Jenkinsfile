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
    stage('Export Docker image') {
  steps {
    sh 'docker save jenkins-python-demo:${BUILD_NUMBER} -o jenkins-python-demo-${BUILD_NUMBER}.tar'
    archiveArtifacts artifacts: 'jenkins-python-demo-*.tar', fingerprint: true
  }
}

stage('Mock deploy') {
  environment {
    DEPLOY_DIR = '/Users/akahlawa/Documents/jenkins-deployments'
  }
  steps {
    sh '''
      mkdir -p "$DEPLOY_DIR"
      cp "jenkins-python-demo-${BUILD_NUMBER}.tar" "$DEPLOY_DIR/"
      printf 'build=%s\nimage=jenkins-python-demo:%s\n' "$BUILD_NUMBER" "$BUILD_NUMBER" \
        > "$DEPLOY_DIR/latest.txt"
    '''
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
