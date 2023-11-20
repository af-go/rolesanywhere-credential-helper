@Library(['meetPaasJenkinsLib']) _

pipeline {
    agent {
        label 'webexkubed-build-worker'
    }
    options {
        ansiColor('xterm')
    }
    stages {
        stage('Lint') {
            agent {
                docker {
                    image 'golang:1.20.7'
                }
            }
            environment {
                GIT_CREDS = credentials("${WBXKUBED_GIT_CREDENTIALS}")
                HOME = '/tmp'
            }
            steps {
                sh '''#!/bin/bash -ex
                    export GITHUB_TOKEN="$GIT_CREDS_PSW"
                    git config --global \
                        url.https://${GITHUB_TOKEN}@sqbu-github.cisco.com.insteadOf \
                        https://sqbu-github.cisco.com
                    make lint
                '''
            }
        }
        stage('Build and Test') {
            agent {
                docker {
                    image 'golang:1.20.7'
                    reuseNode true
                }
            }
            environment {
                HOME = '/tmp'
            }
            steps {
                script {
                    withKubedCreds([githubPull: 'GITHUB_TOKEN']) {
                        sh '''#!/bin/bash -ex
                            git config --global \
                                url.https://${GITHUB_TOKEN}@sqbu-github.cisco.com.insteadOf \
                                https://sqbu-github.cisco.com
                            ./build.bash
                        '''
                    }
                }
            }
        }
        stage('Build and Publish') {
            agent {
                docker {
                    image 'goreleaser/goreleaser:v1.20.0'
                    args '--entrypoint ""'
                    reuseNode true
                }
            }
            options {
                timeout(time: 1, unit: "HOURS")
            }
            environment {
                HOME = '/tmp'
                // We set SNAPSHOT_PARAM to a blank string when building a tag so that we
                // don't build a snapshot build and we actually publish with goreleaser
                SNAPSHOT_PARAM = "${TAG_NAME ? '' : '--snapshot' }"
            }
            steps {
                script {
                    withKubedCreds([githubRelease: 'GITHUB_TOKEN']) {
                        sh '''#!/bin/bash -ex
                            git reset --hard
                            git clean -d -x -f
                            goreleaser release --rm-dist ${SNAPSHOT_PARAM} --timeout 60m
                        '''
                    }
                }
            }
        }
    }
    post {
        cleanup {
            echo 'Cleaning workspace'
            cleanWs()
        }
    }
}