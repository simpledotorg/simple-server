docker-up:
	docker-compose -f .docker/docker-compose.yml up
docker-down:
	docker-compose -f  .docker/docker-compose.yml down --volumes
