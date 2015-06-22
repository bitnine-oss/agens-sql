###########################################################
#
#  Agens SQL
#  Copyright 2014 by Bitnine Co., Ltd. All Right Reserved.
#
###########################################################

# 이 문서는 Agens SQL을 설치하기 위해서 필요한 소프트웨어들과 관련된 의존성 패키지들을 기술한 문서입니다.
# build script가 정상적으로 작동하기 위해서는 이하의 내용들이 정상적으로 설치되어 있어야 합니다.
# Agens SQL는 다음의 소프트웨어를 포함하고 있습니다.
#  - postgresql 
#  - postgis : gdal, geos, proj가 필요합니다.
#  - pgbouncer : libevent가 필요합니다.
#  - pgpool-II
#  - skytools(pgq)
#  - slony
#  - powa

# 이 문서에는 2015년 5월 29일에 apt-get install을 이용하여 설치 가능한 패키지들이 기재되어 있습니다.
# Agens SQL을 설치하기 전에 본인의 컴퓨터의 패키지들을 업데이트 해주세요.
apt-get update -y && apt-get upgrade -y

# postgres를 설치하기 위한 패키지
apt-get install -y build-essential gcc libreadline-dev zlib1g-dev bison flex

# "make world; make install-world" 명령어를 이용해 contrib을 build하기 위해서는 각각의 필요한 의존성 패키지가 설치되어 있어야 합니다.
# postgres에서 docbook을 설치하기 위한 패키지
apt-get install -y openjade docbook docbook-dsssl docbook-xsl openjade1.3 opensp xsltproc

# --with-perl을 위한 패키지
apt-get install -y libperl-dev
# --with-gssapi를 위한 패키지
apt-get install -y krb5-*
# --with-openssl을 위한 패키지
apt-get install -y openssl
# --with-libxslt를 위한 패키지
apt-get install -y libxslt1-dev
# --with-ldap을 위한 패키지
apt-get install -y libldap2-dev
# --with-tcl을 위한 패키지
apt-get install -y tcl-dev

# pgpool-II를 설치하기 위한 패키지
apt-get install -y libpq-dev

# postgis를 설치하기 위한 패키지
apt-get install -y libtiff5-dev python libjson-c-dev libxml2-dev

# libevent를 설치하기 위한 패키지 
apt-get install -y automake git autoconf libtool autoconf-archive asciidoc xmlto pkg-config

# skytools를 설치하기 위한 패키지
apt-get install -y libpq-dev python python-dev autoconf asciidoc xmlto rsync

# izpack을 구동하기 위해 필요한 java / 1.7 버젼을 권장합니다.
apt-get install -y openjdk-7-jdk
