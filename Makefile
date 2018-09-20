export JENKINS_USER=jenkins
export HOSTNAME=$(shell uname -n)

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  checkJava		to check/install Java runtime."
	@echo "  install		to check and install Java and Python dependencies."
	@echo "  docker			to build a docker container"
	@echo "  fabric			to configure jenkins local volume and other dependencies"
	@echo "  build			to build a docker container and configure jenkins local volume"
	@echo "  run 			to run pre-built jenkins container"
	@echo "  start  		to start an existing jenkins container"
	@echo "  stop   		to stop an existing jenkins container"
	@echo "  clean      	to stop and delete jenkins container"
	@echo "  superclean     to clean and delete jenkins user and /home/jenkins"
	@echo "  log      		to see the logs of a running container"
	@echo "  shell      	to execute a shell on jenkins container"

checkJava:
	bash -c "./.checkJava.sh"

install: checkJava
	pip install --user fabric==1.12.2
	export PATH=${HOME}/.local/bin:${PATH}
	@echo

docker:
	@docker build -t ska-sa-cbf/${JENKINS_USER} .
sonar:
	@docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube
fabric:
	@echo "Running Fabric on $(HOSTNAME)"
	@fab -H ${HOSTNAME} setup_cbftest_user
	@fab -H ${HOSTNAME} setup_jenkins_user
	@fab -H ${HOSTNAME} -u ${USER} checkout_cbf_jenkins_config

build: docker fabric sonar

run:
	@sudo /etc/init.d/jenkins-swarm-client.sh start || true;
	@docker run --restart=on-failure:10 -d --name=${JENKINS_USER} -p 8080:8080 -p 50000:50000 -v /home/${JENKINS_USER}:/var/jenkins_home ska-sa-cbf/${JENKINS_USER}

bootstrap: install build run

start:
	@sudo /etc/init.d/jenkins-swarm-client.sh start
	@docker start ${JENKINS_USER}
	@docker start sonarqube || true

stop:
	@sudo /etc/init.d/jenkins-swarm-client.sh stop || true
	@docker stop ${JENKINS_USER} || true
	@docker stop sonarqube || true

clean: stop
	@docker rm -v ${JENKINS_USER} || true
	@docker rm -v sonarqube || true

superclean: clean
	@docker rmi ska-sa-cbf/${JENKINS_USER} || true
	@sudo userdel -f -r ${JENKINS_USER} || true
	@sudo rm -rf /etc/init.d/jenkins-swarm-client.sh || true

log:
	@docker logs -f ${JENKINS_USER}

shell:
	@docker exec -it ${JENKINS_USER} /bin/bash
