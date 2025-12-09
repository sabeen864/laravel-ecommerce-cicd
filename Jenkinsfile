pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Deploy') {
            steps {
                sh '''
                cd ${WORKSPACE}
                # Get public IP
                PUBLIC_IP=$(timeout 5 curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "13.27.51.77")
                echo "Deploying to: http://${PUBLIC_IP}:8081"

                # Deploy
                docker pull sabeen123/laravel-ecommerce:latest
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true

                # Config
                cp .env.example .env
                sed -i "s|APP_URL=.*|APP_URL=http://${PUBLIC_IP}:8081|g" .env
                sed -i "s|DB_HOST=.*|DB_HOST=db|g" .env
                sed -i "s|DB_DATABASE=.*|DB_DATABASE=clothing|g" .env
                sed -i "s|DB_USERNAME=.*|DB_USERNAME=laravel|g" .env
                sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=secret|g" .env
                sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|g" .env

                # Up
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans

                # Setup with proper permissions
                echo "⏳ Waiting for containers..."
                sleep 15
                
                docker cp .env cicd-app-1:/var/www/.env
                
                # FIX: Set all Laravel permissions properly
                echo "🔧 Setting permissions..."
                docker exec -u root cicd-app-1 chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chmod -R 775 /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chown www-data:www-data /var/www/.env
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env
                
                # Run artisan commands (with || true to continue on errors)
                echo "🚀 Running Laravel commands..."
                docker exec cicd-app-1 php artisan cache:clear || true
                docker exec cicd-app-1 php artisan config:clear || true
                docker exec cicd-app-1 php artisan migrate --force || true
                docker exec cicd-app-1 php artisan storage:link || true
                docker exec cicd-app-1 php artisan config:cache || true

                echo "✅ LIVE: http://${PUBLIC_IP}:8081"
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'markhobson/maven-chrome:latest'
                    args '-u 0:0 --network host --privileged --shm-size=2g -v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                script {
                    // Wait for app to be healthy
                    sh '''
                        echo "⏳ Waiting for application to be ready..."
                        for i in {1..30}; do
                            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://13.27.51.77:8081 || echo "000")
                            if [ "$HTTP_CODE" = "200" ]; then
                                echo "✅ Application is ready! (HTTP $HTTP_CODE)"
                                break
                            fi
                            echo "Attempt $i/30: Got HTTP $HTTP_CODE, waiting..."
                            sleep 2
                        done
                    '''
                    
                    echo 'Starting Selenium UI Tests...'
                    sh '''
                        rm -rf laravel-ecommerce-tests
                        git clone https://github.com/sabeen864/laravel-ecommerce-tests.git
                        cd laravel-ecommerce-tests

                        echo "Running Maven tests..."
                        mvn -B -Dmaven.repo.local=./.m2/repository \
                        -Dwdm.cachePath=./.m2/wdm \
                        -Dsurefire.useFile=false \
                        clean test | grep -v "Downloading"
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    archiveArtifacts artifacts: '**/target/surefire-reports/*', allowEmptyArchive: true
                }
            }
        }
    }
    post {
        always {
            script {
                def gitEmail = sh(script: "git log -1 --pretty=format:'%ae'", returnStdout: true).trim()
                def recipient = (gitEmail.contains('internal') || gitEmail.isEmpty()) ? 'syedasabeen61@gmail.com' : gitEmail

                echo "📧 Sending report to: ${recipient}"

                def status = currentBuild.result ?: 'SUCCESS'
                def icon = status == 'SUCCESS' ? '✅' : '❌'
                def color = status == 'SUCCESS' ? 'green' : 'red'

                emailext(
                    to: recipient,
                    subject: "${icon} CI/CD Build #${BUILD_NUMBER}: ${status}",
                    body: """
                        <h2 style="color:${color}">${icon} Build ${status}</h2>
                        <p><strong>Job:</strong> ${JOB_NAME} #${BUILD_NUMBER}</p>
                        <p><strong>App URL:</strong> <a href="http://13.27.51.77:8081">http://13.27.51.77:8081</a></p>
                        <p><strong>Console:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                    """,
                    mimeType: 'text/html'
                )
            }
        }
    }
}
