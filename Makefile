export JENKINS_USER=jenkins
export HOSTNAME=$(shell uname -n)

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  checkJava			to check/install Java runtime."
	@echo "  docker			to build a cbf-test/jenkins docker container"
	@echo "  build				to build a docker container, configure jenkins local volume, configure sonarqube and portainer"
	@echo "  install			to check and install Java and Python dependencies."
	@echo "  fabric			to configure jenkins local volume and other dependencies"
	@echo ""
	@echo "  run 				to run pre-built jenkins container"
	@echo "  start  			to start an existing jenkins container"
	@echo "  stop   			to stop an existing jenkins container"
	@echo ""
	@echo "  log      			to see the logs of a running container"
	@echo "  shell      			to execute a shell on jenkins container"
	@echo ""
	@echo "  sonar      			to run sonarqube container"
	@echo "  sonar_start      		to start sonarqube container"
	@echo "  sonar_stop      		to stop sonarqube container"
	@echo ""
	@echo "  portainer      		to run portainer container"
	@echo "  portainer_start     		to start portainer container"
	@echo "  portainer_stop  		to stop portainer container"
	@echo ""
	@echo "  start_all  			to start all containers defined"
	@echo "  stop_all  			to stop all containers defined"
	@echo ""
	@echo "  clean      			to stop and delete jenkins container"
	@echo "  superclean     		to clean and delete jenkins user and /home/jenkins"

checkJava:
	bash -c "./.checkJava.sh" || true

install: checkJava
	pip install --user fabric==1.12.2
	export PATH=${HOME}/.local/bin:${PATH}
	@echo

docker:
	@docker build -t ska-sa-cbf/${JENKINS_USER} .

sonar:
	@docker run --restart=on-failure:10 -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube

portainer:
	@docker volume create --name=portainer_data
	@docker run --restart=on-failure:10 -d --name portainer -p 9001:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer

fabric:
	@echo "Running Fabric on $(HOSTNAME)"
	@fab -H ${HOSTNAME} setup_cbftest_user
	@fab -H ${HOSTNAME} setup_jenkins_user
	@fab -H ${HOSTNAME} -u ${USER} checkout_cbf_jenkins_config

build: docker fabric sonar portainer

run:
	@sudo /etc/init.d/jenkins-swarm-client.sh start || true;
	@docker run --restart=on-failure:10 -d --name=${JENKINS_USER} -p 8080:8080 -p 50000:50000 -v /home/${JENKINS_USER}:/var/jenkins_home ska-sa-cbf/${JENKINS_USER}

bootstrap: install build run

start:
	@sudo /etc/init.d/jenkins-swarm-client.sh start || true
	@docker start ${JENKINS_USER} || true

stop:
	@sudo /etc/init.d/jenkins-swarm-client.sh stop || true
	@docker stop ${JENKINS_USER} || true

portainer_start:
	@docker start portainer || true

portainer_stop:
	@docker stop portainer || true

sonar_start:
	@docker start sonarqube || true

sonar_stop:
	@docker stop sonarqube || true

stop_all: stop portainer_stop sonar_stop

start_all: start portainer_start sonar_start

clean: stop_all
	@docker rm -v ${JENKINS_USER} || true
	@docker rm -v sonarqube || true
	@docker rm -v portainer || true
	@docker volume rm portainer || true

superclean: clean
	@docker rmi ska-sa-cbf/${JENKINS_USER} || true
	@docker rmi portainer || true
	@sudo userdel -f -r ${JENKINS_USER} || true
	@sudo rm -rf /etc/init.d/jenkins-swarm-client.sh || true

log:
	@docker logs -f ${JENKINS_USER}

shell:
	@docker exec -it ${JENKINS_USER} /bin/bash
