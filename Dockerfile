FROM ubuntu:22.04
MAINTAINER Alper Kucukural <alper.kucukural@umassmed.edu>
RUN apt-get update
# RUN apt-get -y upgrade
# RUN apt-get -y dist-upgrade
 
# Install apache, PHP, and supplimentary programs. curl and lynx-cur are for debugging the container.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 \
                    curl mysql-server libreadline-dev libsqlite3-dev libbz2-dev libssl-dev python2 python2-dev \
                    libmysqlclient-dev  git expect default-jre default-jdk \
                    libxml2-dev software-properties-common gdebi-core wget \
                    tree vim libv8-dev subversion g++ gcc gfortran zlib1g-dev libreadline-dev \
                    libx11-dev xorg-dev libbz2-dev liblzma-dev libpcre3-dev libcurl4-openssl-dev \
                    bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 sendmail \
                    mercurial subversion libarchive-dev uuid-dev squashfs-tools build-essential \
                    libgpgme11-dev libseccomp-dev pkg-config cron rsync


RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt install -y python3.9  python3.9-dev python3.9-distutils 
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py
RUN pip3.9 install simple-crypt mysql-connector-python six natsort
## Needed to install pycryptodome 3.5 first to fix SHA256_init' not found error
RUN pip3.9 install pycryptodome==3.5 && pip3.9 install pycryptodome==3.10.1
RUN ln -s /usr/bin/python3.9 /usr/bin/python
# RUN apt-get clean
RUN apt-get update
RUN apt-get -y install php ssh openssh-server cron \
    php-pear php-curl php-dev php-gd php-mbstring php-zip php-mysql \ 
    php-xml php-ldap s3cmd
# Enable apache mods.
RUN a2enmod rewrite

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/8.1/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/8.1/apache2/php.ini
 
# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf
RUN a2enconf fqdn

RUN echo "locale-gen en_US.UTF-8"
RUN echo "dpkg-reconfigure locales"
 
# RUN service apache2 start 
# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cron phpmyadmin php8.1-mbstring  

# RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && \
#     cat /usr/share/doc/phpmyadmin/examples/create_tables.sql|mysql -uroot

# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin
# RUN usermod -d /var/lib/mysql/ mysql

# RUN sed -i "s#// \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#g" /etc/phpmyadmin/config.inc.php 
# RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
# RUN sed -i 's/localhost/127.0.0.1/' /etc/phpmyadmin/config-db.php 

# RUN apt-get -y autoremove

# Define working directory.
WORKDIR /data

RUN curl -s https://get.nextflow.io | bash 
RUN mv /data/nextflow /usr/bin/.
RUN chmod 755 /usr/bin/nextflow
RUN mkdir /.nextflow
RUN chmod 777 /.nextflow
                     
RUN wget https://phar.phpunit.de/phpunit-8.1.0.phar
RUN chmod +x phpunit-8.1.0.phar
RUN mv phpunit-8.1.0.phar /usr/local/bin/phpunit

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# ENV GITUSER=UMMS-Biocore
# RUN git clone -b 2.0 https://github.com/${GITUSER}/dolphinnext.git /var/www/html/dolphinnext
# RUN git config --global --add safe.directory /export/dolphinnext

RUN mkdir -p /var/www/html/dolphinnext
COPY ./dolphinnext /var/www/html/dolphinnext

RUN chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html/dolphinnext
# RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && \  
#     mysql -u root -e 'CREATE DATABASE dolphinnext;' && \
#     cat /var/www/html/dolphinnext/db/dolphinnext.sql|mysql -uroot dolphinnext &&\
#     mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" &&\ 
#     python /var/www/html/dolphinnext/scripts/updateDN.py

## edirect
RUN cd /usr/local/share && sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
RUN mv /root/edirect/* /usr/local/sbin/.

# Singularity and GO
RUN export VERSION=1.13 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    export VERSION=3.7.4 && \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-${VERSION}.tar.gz && \
    cd singularity && ./mconfig && make -C ./builddir && make -C ./builddir install

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y cryptsetup
ENV PATH $PATH:/usr/local/go/bin

# Downloading gcloud package
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

# AWS CLI
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install unzip sudo
RUN cd ~ && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install

RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -q -y mysql-server
RUN printf "[mysqld]\ndefault-authentication-plugin = mysql_native_password" >> /etc/mysql/my.cnf

# to fix error: Operation not supported: could not create accept mutex
RUN echo 'Mutex posixsem' >>/etc/apache2/apache2.conf

RUN apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN printf "    PubkeyAcceptedAlgorithms +ssh-rsa\n    HostkeyAlgorithms +ssh-rsa\n" >>/etc/ssh/ssh_config 

ADD bin /usr/local/bin

RUN echo "DONE!"

EXPOSE 80
EXPOSE 22

ENTRYPOINT ["/usr/local/bin/startup"]
