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

fabric:
	@echo "Running Fabric on $(HOSTNAME)"
	@fab -H ${HOSTNAME} setup_cbftest_user
	@fab -H ${HOSTNAME} setup_jenkins_user
	@fab -H ${HOSTNAME} -u ${USER} checkout_cbf_jenkins_config

build: docker fabric

run:
	@docker run -d --name=${JENKINS_USER} --env JAVA_OPTS="-Xmx8192m" -p 8080:8080 -p 50000:50000 -v /home/${JENKINS_USER}:/var/jenkins_home ska-sa-cbf/${JENKINS_USER}

bootstrap: install build run

start:
	@docker start ${JENKINS_USER}

stop:
	@docker stop ${JENKINS_USER}

clean: stop
	@docker rm -v ${JENKINS_USER}

superclean: clean
	@docker rmi ska-sa-cbf/${JENKINS_USER}
	@sudo userdel -f -r ${JENKINS_USER}

log:
	@docker logs -f ${JENKINS_USER}

shell:
	@docker exec -it ${JENKINS_USER} /bin/bash
