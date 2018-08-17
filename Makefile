export JENKINS_USER=jenkins

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  install		to install Python dependencies."
	@echo "  build			to build a docker container and configure jenkins local volume"
	@echo "  run 			to run pre-built jenkins container"
	@echo "  start  		to start an existing jenkins container"
	@echo "  stop   		to stop an existing jenkins container"
	@echo "  clean      	to stop and delete jenkins container"
	@echo "  superclean     to clean and delete jenkins user and /home/jenkins"
	@echo "  log      		to see the logs of a running container"
	@echo "  shell      	to execute a shell on jenkins container"

install:
	pip install --user fabric==1.12.2
	export PATH=${HOME}/.local/bin:${PATH}

build:
	@docker build -t ska-sa-cbf/${JENKINS_USER} .
	@fab setup_jenkins_user
	@fab -u ${USER} checkout_cbf_jenkins_config

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
	@sudo rm -rf /home/${JENKINS_USER}
	@sudo userdel -f -r ${JENKINS_USER}

log:
	@docker logs -f ${JENKINS_USER}

shell:
	@docker exec -it ${JENKINS_USER} /bin/bash
