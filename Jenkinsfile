pipeline {
	agent {
		docker { image 'debian' }
	}
	stages {
		stage('Test') {
			steps {
				sh 'bin/dotfiles --install'
			}
		}
	}
}
