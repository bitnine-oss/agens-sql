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

# 이 문서에는 2015년 6월 24일에 yum install을 이용하여 설치 가능한 패키지들이 기재되어 있습니다.
# Agens SQL을 설치하기 전에 본인의 컴퓨터의 패키지들을 업데이트 해주세요.
yum update -y && yum upgrade -y

# postgres를 설치하기 위한 패키지
yum groupinstall -y "Development Tools"
yum install -y gcc zlib-devel.* readline-devel.*

# "make world; make install-world" 명령어를 이용해 contrib을 build하기 위해서는 각각의 필요한 의존성 패키지가 설치되어 있어야 합니다.
# postgres에서 docbook을 설치하기 위한 패키지
yum install -y openjade.* docbook-style-dsssl.noarch

# --with-perl을 위한 패키지
yum install -y perl-YAML* perl-ExtUtils*
# --with-gssapi를 위한 패키지
yum install -y krb5-*
# --with-openssl을 위한 패키지
yum install -y openssl-devel.*
# --with-libxslt를 위한 패키지
yum install -y libxslt-devel.*
# --with-ldap을 위한 패키지
yum install -y openldap-devel.*
# --with-tcl을 위한 패키지
yum install -y tcl-devel.*
# --with-pam을 위한 패키지
yum install -y pam-devel.*

# postgis를 설치하기 위한 패키지
yum install -y libtiff-devel.* json-c-devel.* libxml2-devel.* python-devel.*

# skytools를 설치하기 위한 패키지
yum install -y python-devel.*

# izpack을 구동하기 위해 필요한 java / 1.7 버젼을 권장합니다.
yum install -y java-1.7.0-openjdk-devel.* 
