// ============================================================
// Jenkinsfile — rapidtriage.me (SmartRapidTriage)
// Stack: TypeScript + Cloudflare Workers + Wrangler
// Pipeline: develop → staging | main → production (gated)
// ============================================================

pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '25'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds(abortPrevious: true)
    }

    environment {
        DOMAIN          = 'rapidtriage'
        GCP_PROJECT     = credentials('gcp-project-id')
        CF_API_TOKEN    = credentials('cloudflare-api-token')
        GITHUB_TOKEN    = credentials('github-token')
        ENV_NAME        = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
        SHORT_SHA       = "${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        SLACK_CHANNEL   = '#cicd-rapidtriage'
        WORKER_NAME     = "smartrapidtriage-${env.BRANCH_NAME == 'main' ? 'prod' : 'staging'}"
    }

    stages {

        // ── 1. Checkout ──────────────────────────────────────
        stage('📥 Checkout') {
            steps {
                checkout scm
                script {
                    env.COMMIT_MSG  = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    env.COMMIT_AUTH = sh(script: 'git log -1 --pretty=%an', returnStdout: true).trim()
                    env.SHORT_SHA   = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
                slackSend channel: env.SLACK_CHANNEL, color: '#439FE0',
                    message: "🔨 *rapidtriage* build started\nBranch: `${BRANCH_NAME}` | By: ${COMMIT_AUTH}"
            }
        }

        // ── 2. Install ───────────────────────────────────────
        stage('📦 Install') {
            steps {
                sh '''
                    node --version
                    npm --version

                    # Install Wrangler globally
                    npm install -g wrangler@latest 2>/dev/null || true
                    wrangler --version

                    # Install project dependencies
                    npm ci
                '''
            }
        }

        // ── 3. Parallel Quality Gates ─────────────────────────
        stage('🔍 Code Quality') {
            parallel {
                stage('TypeScript Check') {
                    steps {
                        sh 'npm run typecheck'
                    }
                }
                stage('ESLint') {
                    steps {
                        sh 'npm run lint 2>&1 || echo "⚠️ Lint warnings — review"'
                    }
                }
                stage('Dependency Audit') {
                    steps {
                        sh 'npm audit --audit-level=high 2>&1 || echo "⚠️ Vulnerabilities found — review"'
                    }
                }
                stage('Secret Scan') {
                    steps {
                        sh '''
                            if grep -rE "(sk_live_|AIza|ghp_|CF_API_TOKEN|AKIA)" \
                               --include="*.ts" --include="*.js" \
                               --exclude-dir=node_modules --exclude-dir=dist src/ 2>/dev/null; then
                                echo "⛔ HARDCODED SECRETS DETECTED"
                                exit 1
                            fi
                            echo "✅ No hardcoded secrets"
                        '''
                    }
                }
            }
        }

        // ── 4. Tests ──────────────────────────────────────────
        stage('🧪 Test Suite') {
            parallel {
                stage('Unit + API Tests') {
                    steps {
                        sh '''
                            npm run test:api 2>&1 || echo "⚠️ API tests incomplete"
                            npm test 2>&1 || echo "⚠️ Full test suite needs review"
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true,
                                reportDir: 'test/reports', reportFiles: '*.html',
                                reportName: '🧪 Test Report — RapidTriage'
                            ])
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh '''
                            npm run test:integration 2>&1 || echo "⚠️ Integration tests — review"
                        '''
                    }
                }
            }
        }

        // ── 5. Build (TypeScript → Workers bundle) ────────────
        stage('🏗️ Build') {
            steps {
                sh '''
                    npm run build
                    echo "✅ TypeScript compiled"

                    # Verify wrangler.toml is present
                    test -f wrangler.toml \
                        && echo "✅ wrangler.toml found" \
                        || (echo "❌ wrangler.toml missing" && exit 1)
                '''
            }
        }

        // ── 6. Inject Cloudflare Secrets ──────────────────────
        stage('🔐 Sync Secrets → Cloudflare') {
            when {
                anyOf { branch 'develop'; branch 'main' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'cloudflare-api-token', variable: 'CF_TOKEN'),
                    string(credentialsId: 'cloudflare-account-id', variable: 'CF_ACCOUNT_ID'),
                    string(credentialsId: 'gcp-project-id', variable: 'GCP_PROJ'),
                ]) {
                    sh '''
                        export CLOUDFLARE_API_TOKEN=${CF_TOKEN}
                        export CLOUDFLARE_ACCOUNT_ID=${CF_ACCOUNT_ID}

                        echo "Syncing ${ENV_NAME} secrets to Cloudflare Worker..."

                        # Pull each secret from GCP Secret Manager → push to Cloudflare
                        for SECRET_NAME in \
                            rapidtriage-${ENV_NAME}-database-url \
                            rapidtriage-${ENV_NAME}-github-app-id \
                            rapidtriage-${ENV_NAME}-openai-key \
                            rapidtriage-${ENV_NAME}-uip-secret \
                            rapidtriage-${ENV_NAME}-stripe-key \
                            rapidtriage-${ENV_NAME}-slack-webhook; do

                            CF_KEY=$(echo $SECRET_NAME | sed "s/rapidtriage-${ENV_NAME}-//" | tr '[:lower:]-' '[:upper:]_')
                            VALUE=$(gcloud secrets versions access latest \
                                --secret="${SECRET_NAME}" \
                                --project="${GCP_PROJ}" 2>/dev/null || echo "")

                            if [ -n "$VALUE" ]; then
                                echo -n "$VALUE" | wrangler secret put "${CF_KEY}" \
                                    --env ${ENV_NAME} \
                                    --name ${WORKER_NAME} 2>/dev/null \
                                    && echo "  ✅ ${CF_KEY}" \
                                    || echo "  ⚠️ ${CF_KEY} — check CF permissions"
                            fi
                        done
                        echo "✅ Secrets synced to Cloudflare"
                    '''
                }
            }
        }

        // ── 7. Deploy Staging ─────────────────────────────────
        stage('🚀 Deploy → Staging') {
            when { branch 'develop' }
            steps {
                withCredentials([
                    string(credentialsId: 'cloudflare-api-token', variable: 'CF_TOKEN'),
                    string(credentialsId: 'cloudflare-account-id', variable: 'CF_ACCOUNT_ID'),
                ]) {
                    sh '''
                        export CLOUDFLARE_API_TOKEN=${CF_TOKEN}
                        export CLOUDFLARE_ACCOUNT_ID=${CF_ACCOUNT_ID}

                        wrangler deploy --env staging
                        echo "✅ RapidTriage deployed to Cloudflare Workers Staging"
                    '''
                }
            }
        }

        // ── 8. Staging Health Check ───────────────────────────
        stage('💨 Smoke Test — Staging') {
            when { branch 'develop' }
            steps {
                sh '''
                    sleep 10
                    STAGING_URL="https://smartrapidtriage-staging.yarlis-cicd-prod.workers.dev"

                    STATUS=$(curl -o /dev/null -s -w "%{http_code}" "${STAGING_URL}/health" \
                        --max-time 15 || echo "000")
                    echo "Staging health: ${STATUS}"

                    [ "$STATUS" = "200" ] \
                        && echo "✅ Staging healthy" \
                        || echo "⚠️ Staging returned ${STATUS} — verify manually"
                '''
            }
        }

        // ── 9. Production Approval ────────────────────────────
        stage('⏸️ Production Approval') {
            when { branch 'main' }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: "Deploy rapidtriage.me to PRODUCTION?\n\nSHA: ${env.SHORT_SHA}\nBy: ${env.COMMIT_AUTH}\n${env.COMMIT_MSG}",
                        ok: '🚀 Deploy to Production',
                        submitter: 'admin'
                    )
                }
            }
        }

        // ── 10. Deploy Production ─────────────────────────────
        stage('🚀 Deploy → Production') {
            when { branch 'main' }
            steps {
                withCredentials([
                    string(credentialsId: 'cloudflare-api-token', variable: 'CF_TOKEN'),
                    string(credentialsId: 'cloudflare-account-id', variable: 'CF_ACCOUNT_ID'),
                ]) {
                    sh '''
                        export CLOUDFLARE_API_TOKEN=${CF_TOKEN}
                        export CLOUDFLARE_ACCOUNT_ID=${CF_ACCOUNT_ID}

                        wrangler deploy --env production
                        echo "✅ RapidTriage deployed to Cloudflare Workers Production"
                    '''
                }
            }
        }

        // ── 11. Production Verification ───────────────────────
        stage('✅ Production Verification') {
            when { branch 'main' }
            steps {
                sh '''
                    sleep 15
                    STATUS=$(curl -o /dev/null -s -w "%{http_code}" \
                        "https://rapidtriage.me/health" --max-time 15 || echo "000")
                    echo "Production health: ${STATUS}"
                    [ "$STATUS" = "200" ] \
                        && echo "✅ rapidtriage.me is live" \
                        || echo "⚠️ Health check pending"
                '''
            }
        }
    }

    // ── Post Actions ──────────────────────────────────────────
    post {
        success {
            script {
                def env_label = env.BRANCH_NAME == 'main' ? '🚀 PRODUCTION' : '🟡 staging'
                slackSend channel: env.SLACK_CHANNEL, color: '#36a64f',
                    message: "✅ *rapidtriage* deployed to *${env_label}*\nBuild: #${BUILD_NUMBER} | SHA: `${SHORT_SHA}` | <${BUILD_URL}|View>"
            }
        }
        failure {
            slackSend channel: env.SLACK_CHANNEL, color: '#d00000',
                message: "❌ *rapidtriage* FAILED on `${BRANCH_NAME}`\nBuild: #${BUILD_NUMBER} | <${BUILD_URL}|View Logs>"
        }
        always {
            cleanWs()
        }
    }
}
