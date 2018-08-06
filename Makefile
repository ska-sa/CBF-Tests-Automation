build:
	@docker build -t ska-sa-cbf/jenkins .
run:
	@docker run -d --name=jenkins -p 8080:8080 -p 50000:50000 -v /home/jenkins:/var/jenkins_home ska-sa-cbf/jenkins
start:
	@docker start jenkins
stop:
	@docker stop jenkins
clean:
	stop
	@docker rm -v jenkins
log:
	@docker logs -f jenkins
shell:
	@docker exec -it jenkins /bin/bash