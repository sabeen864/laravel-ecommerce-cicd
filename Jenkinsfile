pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        def app = docker.build("sabeen123/laravel-ecommerce:latest")
                        app.push()
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                cd ~/laravel-ecommerce-cicd
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment successful! App is live on http://3.106.170.54:8081'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
