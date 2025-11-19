// Jenkinsfile (Declarative)
pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = 'dockerhub-creds'         // Jenkins credential id for Docker Hub (username/password)
    SSH_CREDENTIALS = 'remote-ssh-key'                // Jenkins credential id for SSH private key
    REMOTE_USER = 'ubuntu'                            // remote server username
    REMOTE_HOST = 'your.remote.server.ip'             // set in Jenkins job or set as parameter
    IMAGE_NAME = "devops-flask-project"
    DOCKERHUB_USER = "YOUR_DOCKERHUB_USERNAME"        // replace or set via Jenkins Parameter
    DEPLOY_PATH = "/home/ubuntu/remote-docker-compose.yml" // path to compose on remote
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/YOUR_USERNAME/YOUR_REPO.git', branch: 'main'  // change to your repo
      }
    }

    stage('Run unit tests') {
      steps {
        dir('app') {
          sh '''
            python3 -m venv .venv
            . .venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt
            pytest -q
          '''
        }
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          def commit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          def branch = env.GIT_BRANCH?.replaceAll('/','-') ?: 'main'
          env.IMAGE_TAG = "${branch}-${commit}"
          sh "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.IMAGE_TAG} ."
          sh "docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.IMAGE_TAG} ${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
            docker logout
          '''
        }
      }
    }

    stage('Deploy to Remote Server') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS, keyFileVariable: 'SSH_KEY')]) {
          script {
            // Copy remote compose (if needed) and run deploy script via ssh
            sh """
              scp -i ${SSH_KEY} -o StrictHostKeyChecking=no scripts/remote-docker-compose.yml ${REMOTE_USER}@${REMOTE_HOST}:${DEPLOY_PATH}
              ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'bash -s' <<'ENDSSH'
                set -e
                # run commands to pull and update container with the new tag
                # change image tag inside compose to exact tag
                sed -i "s|image: ${DOCKERHUB_USER}/${IMAGE_NAME}.*|image: ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}|g" ${DEPLOY_PATH}
                docker compose -f ${DEPLOY_PATH} pull
                docker compose -f ${DEPLOY_PATH} up -d
                exit
ENDSSH
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo "Build, push and deploy completed successfully."
    }
    failure {
      echo "Pipeline failed."
    }
  }
}
