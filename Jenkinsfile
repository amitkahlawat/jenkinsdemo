pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(
      logRotator(
        numToKeepStr: '10',
        artifactNumToKeepStr: '5'
      )
    )
  }

  parameters {
    choice(
      name: 'DEPLOY_ENV',
      choices: ['dev', 'test'],
      description: 'Choose the local mock deployment environment'
    )

    booleanParam(
      name: 'DEPLOY_ENABLED',
      defaultValue: true,
      description: 'Deploy after approval'
    )
  }

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

    stage('Set up test environment') {
      steps {
        sh '''
          python3 -m venv .venv
          .venv/bin/python -m pip install --upgrade pip
          .venv/bin/python -m pip install -r requirements-dev.txt
        '''
      }
    }

    stage('Python unit test') {
      steps {
        sh '.venv/bin/python -m pytest -q --junitxml=test-results.xml'
      }

      post {
        always {
          junit allowEmptyResults: true, testResults: 'test-results.xml'
        }
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

    stage('Docker health check') {
      steps {
        sh '''
          docker run -d --rm \
            --name "jenkins-health-${BUILD_NUMBER}" \
            -p 18080:8080 \
            "$IMAGE_TAG"

          for attempt in 1 2 3 4 5; do
            if curl --fail --silent http://localhost:18080/health | grep -q '"status":"healthy"'; then
              echo "Health check passed."
              exit 0
            fi
            sleep 1
          done

          docker logs "jenkins-health-${BUILD_NUMBER}"
          exit 1
        '''
      }

      post {
        always {
          sh 'docker stop "jenkins-health-${BUILD_NUMBER}" || true'
        }
      }
    }

    stage('Export Docker image') {
      steps {
        sh 'docker save "$IMAGE_TAG" -o "$IMAGE_ARCHIVE"'
        archiveArtifacts artifacts: 'jenkins-python-demo-*.tar', fingerprint: true
      }
    }

    stage('Approve mock deployment') {
      when {
        allOf {
          expression { !env.BRANCH_NAME || env.BRANCH_NAME == 'main' }
          expression {
            sh(
              script: "git log -1 --pretty=%B | grep -q '\\[skip ci\\]'",
              returnStatus: true
            ) != 0
          }
        }
      }

      steps {
        timeout(time: 10, unit: 'MINUTES') {
          input(
            message: "Deploy ${IMAGE_TAG} to the local mock environment?",
            ok: 'Approve deployment'
          )
        }
      }
    }

    stage('Mock deploy') {
      when {
        allOf {
          expression { !env.BRANCH_NAME || env.BRANCH_NAME == 'main' }
          expression { params.DEPLOY_ENABLED }
          expression {
            sh(
              script: "git log -1 --pretty=%B | grep -q '\\[skip ci\\]'",
              returnStatus: true
            ) != 0
          }
        }
      }

      steps {
        sh '''
          DEPLOY_ENV="${DEPLOY_ENV:-dev}"
          DEPLOY_DIR="/Users/akahlawa/Documents/jenkins-deployments/${DEPLOY_ENV}"

          mkdir -p "$DEPLOY_DIR"
          cp "$IMAGE_ARCHIVE" "$DEPLOY_DIR/"

          printf 'environment=%s\nbranch=%s\nbuild=%s\nimage=%s\n' \
            "$DEPLOY_ENV" "${BRANCH_NAME:-main}" "$BUILD_NUMBER" "$IMAGE_TAG" \
            > "$DEPLOY_DIR/latest.txt"
        '''
      }
    }

    stage('Publish GitOps image tag') {
      when {
        allOf {
          expression { !env.BRANCH_NAME || env.BRANCH_NAME == 'main' }
          expression { params.DEPLOY_ENABLED }
          expression {
            sh(
              script: "git log -1 --pretty=%B | grep -q '\\[skip ci\\]'",
              returnStatus: true
            ) != 0
          }
        }
      }

      steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'github-jenkins-gitops-push',
            usernameVariable: 'GIT_USERNAME',
            passwordVariable: 'GIT_TOKEN'
          )
        ]) {
          sh '''
            set +x

            git config user.name "jenkins-gitops"
            git config user.email "jenkins-gitops@local"

            sed -E -i '' \
              "s#^[[:space:]]*image: jenkins-python-demo:.*#          image: ${IMAGE_TAG}#" \
              k8s/jenkins-python-demo.yaml

            git add k8s/jenkins-python-demo.yaml

            if git diff --cached --quiet; then
              echo "GitOps manifest already uses ${IMAGE_TAG}."
              exit 0
            fi

            git commit -m "chore(gitops): deploy ${IMAGE_TAG} [skip ci]"

            ASKPASS_FILE="$(mktemp)"
            trap 'rm -f "$ASKPASS_FILE"' EXIT

            cat > "$ASKPASS_FILE" <<'EOF'
#!/bin/sh
case "$1" in
  *Username*) printf '%s\n' "$GIT_USERNAME" ;;
  *Password*) printf '%s\n' "$GIT_TOKEN" ;;
esac
EOF

            chmod 700 "$ASKPASS_FILE"

            GIT_ASKPASS="$ASKPASS_FILE" \
            GIT_TERMINAL_PROMPT=0 \
            git push https://github.com/amitkahlawat/jenkinsdemo.git HEAD:main
          '''
        }
      }
    }
  }
}
