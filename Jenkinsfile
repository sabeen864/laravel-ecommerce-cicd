pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image') {
            steps {
                sh '''
                docker build -t sabeen123/laravel-ecommerce:latest .
                docker push sabeen123/laravel-ecommerce:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                mkdir -p ~/laravel-ecommerce-cicd
                cp -r * ~/laravel-ecommerce-cicd/ || true
                cp .env.example .env 2>/dev/null || true

                chmod -R 777 storage bootstrap/cache
                cd ~/laravel-ecommerce-cicd

                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans --remove-orphans
                sleep 10
                docker exec cicd-app-1 composer install --no-dev --optimize-autoloader





                docker exec cicd-app-1 php artisan view:cache




                '''
            }
        }
    }

    post {
        success { echo 'LIVE: http://13.54.247.55:8081' }
        failure { echo 'FAILED!' }
    }
}
