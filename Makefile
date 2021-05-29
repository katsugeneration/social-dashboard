setdev:
	docker volume create devenv

build:
	docker-compose build

updev:
	docker-compose up -d

downdev:
	docker-compose down