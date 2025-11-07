pipeline {
    agent any
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build & Push') {
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
                cd ${WORKSPACE}
                cp .env.example .env
                sed -i "s|APP_URL=.*|APP_URL=http://3.106.170.54:8081|g" .env

                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans
                sleep 30

                docker cp .env cicd-app-1:/var/www/.env

                docker exec -u root cicd-app-1 mkdir -p /var/www/storage/logs
                docker exec -u root cicd-app-1 chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/.env
                docker exec -u root cicd-app-1 chmod -R 775 /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env

                docker exec cicd-app-1 composer install --no-dev --optimize-autoloader
                docker exec cicd-app-1 php artisan key:generate --force
                docker exec cicd-app-1 php artisan migrate --force

                docker exec cicd-app-1 php artisan config:cache
                # SKIP route:cache — SAFE FOR PRODUCTION
                docker exec cicd-app-1 php artisan view:cache
                '''
            }
        }
    }
    post {
        success { echo 'LIVE: http://3.106.170.54:8081' }
        failure { echo 'FAILED!' }
    }
}
