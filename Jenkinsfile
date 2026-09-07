pipeline {
  agent any

  environment {
    PATH = "/Users/akahlawa/.rd/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    DEPLOY_DIR = "/Users/akahlawa/Documents/jenkins-deployments"
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

stage('Set release identity') {
  steps {
    sh 'git fetch --tags --force'

    script {
      def branch = env.BRANCH_NAME ?: 'main'
      def safeBranch = branch.replaceAll('[^A-Za-z0-9_.-]', '-')
      def version = sh(
        script: 'git describe --tags --abbrev=0',
        returnStdout: true
      ).trim()

      env.IMAGE_TAG = "jenkins-python-demo:${safeBranch}-${version}-${env.BUILD_NUMBER}"
      env.IMAGE_ARCHIVE = "jenkins-python-demo-${safeBranch}-${version}-${env.BUILD_NUMBER}.tar"
    }

    sh 'echo "Building release image: $IMAGE_TAG"'
  }
}

    stage('Docker build') {
      steps {
        sh 'docker build -t "$IMAGE_TAG" .'
      }
    }

    stage('Docker test') {
      steps {
        sh 'docker run --rm "$IMAGE_TAG"'
      }
    }

    stage('Export Docker image') {
      steps {
        sh 'docker save "$IMAGE_TAG" -o "$IMAGE_ARCHIVE"'
        archiveArtifacts artifacts: 'jenkins-python-demo-*.tar', fingerprint: true
      }
    }

    stage('Mock deploy') {
      when {
        expression { !env.BRANCH_NAME || env.BRANCH_NAME == 'main' }
      }
      steps {
        sh '''
          mkdir -p "$DEPLOY_DIR"
          cp "$IMAGE_ARCHIVE" "$DEPLOY_DIR/"
          printf 'branch=%s\nbuild=%s\nimage=%s\n' \
            "${BRANCH_NAME:-main}" "$BUILD_NUMBER" "$IMAGE_TAG" \
            > "$DEPLOY_DIR/latest.txt"
        '''
      }
    }
  }
}