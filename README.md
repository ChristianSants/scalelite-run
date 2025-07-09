# scalelite-run

A simple way to deploy Scalelite as for production using docker-compose.

## Overview

[Scalelite](https://github.com/blindsidenetworks/scalelite) is an open-source load balancer, designed specifically for [BigBlueButton](https://bigbluebutton.org/), that evenly spreads the meeting load over a pool of BigBlueButton servers. It makes the pool of BigBlueButton servers appear to a front-end application such as Moodle [2], as a single and yet very scalable BigBlueButton server.

It was released by [Blindside Networks](https://blindsidenetworks.com/) under the AGPL license on March 13, 2020, in response to the high demand of Universities looking into scaling BigBlueButton in response to the [COVID-19 pandemic lock-downs](https://campustechnology.com/articles/2020/03/03/coronavirus-pushes-online-learning-forward.aspx).

The full source code is available on GitHub and pre-built docker images can be found on [DockerHub](https://hub.docker.com/r/blindsidenetwks/scalelite).

Scaleite itself is a ruby on rails application.

For its deployment it is required some experience with BigBlueButton and Scalelite itself, and all the tools and components used as part of the stack such as redis, postgres, nginx, docker and docker-compose, as well as ubuntu and AWS infrastructure.

For those new to system administration or any of the components mentioned the article [Scalelite lazy deployment
](https://jffederico.medium.com/scalelite-lazy-deployment-745a7be849f6) is a step-by-step guide on how to complete a full installation of Scalelite on AWS using this script. Also [Scalelite lazy deployment (Part II)](https://jffederico.medium.com/scalelite-lazy-deployment-part-ii-ca3e4bf82f8d) is a step-by-step guide to complete the installation with support for recordings.

## Installation (short version)

On an Ubuntu 22.04 machine available to the Internet (AWS EC2 instance, LXC container, VMWare machine etc).

### Prerequisites

This machine needs to be updated and have installed:

- Git
- [Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04)
- [Docker Compose](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)

### Fetching the scripts

```
git clone https://github.com/jfederico/scalelite-run
cd scalelite-run
```

### Initializing environment variables

Create a new .env file based on the dotenv file included.

```
cp dotenv .env
```

Most required variables are pre-set by default, the ones that must be set before starting are:

```
SECRET_KEY_BASE=
LOADBALANCER_SECRET=
SL_HOST=
DOMAIN_NAME=
```

Obtain the value for SECRET_KEY_BASE and LOADBALANCER_SECRET with:

```
sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env
sed -i "s/LOADBALANCER_SECRET=.*/LOADBALANCER_SECRET=$(openssl rand -hex 24)/" .env
```

Set the hostname on SL_HOST (E.g. sl)

```
sed -i "s/SL_HOST=.*/SL_HOST=sl" .env
```

Set the domain name on DOMAIN_NAME (E.g. example.com)

```
sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=example.com" .env
```

Start the services.

```
docker-compose up -d
```

Now, the scalelite server is running, but it is not quite yet ready. The database must be initialized.

```
docker exec -i scalelite-api bundle exec rake db:setup
```

# Extras

Sessão com alguns auxilios que achei necessário para a instalação.

## Instalação do scalelite

- Antes de rodar o docker-compose up -d execute o ./init-letsencrypt.sh (**se não tiver certificado ssl na pasta data/certbot/**), após rodar o ./init-letsencrypt.sh rode o docker-compose up -d;
- Execute o docker exec -i scalelite-api bundle exec rake db:setup;
- Execute o docker exec -i scalelite-api bundle exec rake db:migrate;

### Renovação de certificado automática
Acesse o crontab:
```
crontab -e
```

Coloque este trecho:
```
0 3 25 * * cd /home/ubuntu/scalelite-run-redis-2 && ./renew-cert.sh
```

Obs: coloque o seu caminho para o cd e ajuste o arquivo renew-cert.sh para seu dominio!

## Compartilhamento de gravações entre Scalelite e BBB

Após executar os passos desse tutorial:

https://jffederico.medium.com/scalelite-lazy-deployment-part-ii-ca3e4bf82f8d

- Acesse seu ec2 do scalelite e libere a porta de ssh para o ip público do server BBB;

- Acesse a sua instancia do BBB:
    - Acesse o caminho /usr/local/bigbluebutton/core/scripts/post_publish
    - edite o arquivo post_publish_scalelite.rb
    - altere a linha que tem isso ``` system('rsync', '--verbose', '--remove-source-files', '--protect-args', *extra_rsync_opts, archive_file, spool_dir) \ ``` para ``` system('rsync', '-e', 'ssh -i /home/bigbluebutton/.ssh/id_rsa', '--verbose', '--remove-source-files', '--protect-args', *extra_rsync_opts, archive_file, spool_dir) \ ```
    - crie um arquivo dentro do bbb:  ```sudo -u bigbluebutton touch /home/bigbluebutton/.ssh/config ```;
    - edite:  ```sudo -u bigbluebutton nano /home/bigbluebutton/.ssh/config ```;
    Coloque isso dentro: 
     ```
         Host scalelite-spool
          HostName scalelite.avaedus.com.br
          User bigbluebutton
          Port 22
          IdentityFile /home/bigbluebutton/.ssh/id_rsa
          IdentitiesOnly yes
     ```
    - ajuste a permissaõ:  ```sudo -u bigbluebutton chmod 600 /home/bigbluebutton/.ssh/config ```
    - Após a primeira gravação do bbb se der algum erro no ```bbb-record --list-recent``` tente rodar manualmente o post_publish_scalelite: ```sudo -u bigbluebutton ruby /usr/local/bigbluebutton/core/scripts/post_publish/post_publish_scalelite.rb -m d6209c14d7b6ed89ff89e13e9209a759944d94db-1744136724402```
    - Comando para instalar todos os pacotes necessários:
     ```
       sudo apt-get update
       sudo apt-get install -y ruby-dev libsystemd-dev
       sudo gem install redis builder nokogiri loofah open4 absolute_time journald-logger
     ```
    - Após isso, as novas gravações vão ser transferidas automaticamente.

 ## Ajustes BBB

 Para remover o modal de boas vindas faça isso:
 - ```sudo nano /usr/share/bigbluebutton/html5-client/private/config/settings.yml```
 - mude a variavel **showSessionDetailsOnJoin** de true para false
 - reinicie o bbb: ```sudo bbb-conf --restart```
