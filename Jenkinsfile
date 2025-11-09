pipeline {
    agent any
    stages {
        stage('Checkout') { 
            steps { checkout scm } 
        }
        
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

                # Get current public IP dynamically
                PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
                echo "Deploying to: http://${PUBLIC_IP}:8081"

                # Stop existing containers
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true

                # Update .env file
                cp .env.example .env
                sed -i "s|APP_URL=.*|APP_URL=http://${PUBLIC_IP}:8081|g" .env
                sed -i "s|DB_HOST=.*|DB_HOST=db|g" .env
                sed -i "s|DB_DATABASE=.*|DB_DATABASE=clothing|g" .env
                sed -i "s|DB_USERNAME=.*|DB_USERNAME=laravel|g" .env
                sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=secret|g" .env

                # Start containers
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans

                # Wait for containers
                sleep 20

                # Copy .env into container
                docker cp .env cicd-app-1:/var/www/.env

                # Set permissions
                docker exec -u root cicd-app-1 chown www-data:www-data /var/www/.env
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env

                # Run Laravel setup
                docker exec cicd-app-1 php artisan key:generate --force
                docker exec cicd-app-1 php artisan migrate --force
                docker exec cicd-app-1 php artisan storage:link
                docker exec cicd-app-1 php artisan config:cache
                docker exec cicd-app-1 php artisan route:cache
                
                echo "✅ LIVE: http://${PUBLIC_IP}:8081"
                '''
            }
        }
    }
    post {
        success { 
            echo '✅ DEPLOYMENT SUCCESSFUL!'
        }
        failure { 
            echo '❌ DEPLOYMENT FAILED!' 
        }
    }
}
