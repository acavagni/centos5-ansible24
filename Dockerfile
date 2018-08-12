#
# This is the Dockerfile for building a custom CentOS-5-x86_64 container image
# ready to be deployed as an ansible 2.4 (or newer) target host.
#
# In order to test ansible >= 2.4 on "RHEL 5 like" machines I tought I could
# use Docker containers to quickly spin up multiple CentOS-5 based environments 
# already equipped with:
#   - an sshd server
#   - an ansible user (with password 'ansible' and sudo enabled)
#   - a working yum repository (with epel included)
#   - the python26 intepreter (required to run ansible >= 2.4 on CentOS/RHEL version 5)
#
# New sshd server keys are generated at runtime (on each container run) so, before
# proceeding using ansible, remember to edit your ansible.cfg configuration file and
# add "-o UserKnownHostsFile=/dev/null" to the "ssh_args" parameter and set the
# "host_key_checking" parameter to "False" in order to make ssh logins work.
#
# !!! DISCLAIMER:
# THIS SETUP IS INERENTLY INSECURE AND IT IS INTENDED FOR TESTING PURPOSE ONLY!!!
# PLEASE DO NOT USE IT IN PRODUCTION!!!
#
# Please refer to this article for more details about ansible 2.4 and RHEL5:
#   https://www.ansible.com/blog/using-ansible-to-manage-rhel-5-yesterday-today-and-tomorrow
#
# This image based on:
# https://hub.docker.com/r/astj/centos5-vault/
# 

FROM astj/centos5-vault

MAINTAINER Alessandro Cavagni "https://hub.docker.com/r/acavagni/" version 1.1

EXPOSE 22

RUN \
  rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5 && \
  yum -y install wget sudo && \
  wget https://archives.fedoraproject.org/pub/archive/epel/5/x86_64/epel-release-5-4.noarch.rpm \
       -O /tmp/epel-release-5-4.noarch.rpm && \
  wget https://archives.fedoraproject.org/pub/archive/epel/RPM-GPG-KEY-EPEL-5 \
       -O /tmp/RPM-GPG-KEY-EPEL-5 && \
  rpm --import /tmp/RPM-GPG-KEY-EPEL-5 && \
  yum -y install /tmp/epel-release-5-4.noarch.rpm && \
  yum -y install python26 && \
  useradd -c "User for Testing Ansible >= 2.4" -G wheel -m ansible && \
  echo "ansible:ansible" | chpasswd && \
  sed -i -r \
         -e '/^Defaults\s*requiretty/a\Defaults:ansible !requiretty' \
	 -e '/^#\s*%wheel.*NOPASSWD:/s/^#\s*//' /etc/sudoers && \
  yum install -y openssh-server && \
  { \
    echo '#!/bin/bash' > /opt/start_sshd_server.sh && \
    echo "# Generates sshd server keys" >> /opt/start_sshd_server.sh && \
    echo "ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''" >> /opt/start_sshd_server.sh && \
    echo "ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''" >> /opt/start_sshd_server.sh && \
    echo "# Start the sshd server" >> /opt/start_sshd_server.sh && \
    echo "/usr/sbin/sshd -D" >> /opt/start_sshd_server.sh; \
  } && \
  chmod +x /opt/start_sshd_server.sh && \
  yum clean all && \
  rm -rf /tmp/*
  
CMD ["/opt/start_sshd_server.sh"]
