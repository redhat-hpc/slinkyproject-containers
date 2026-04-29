FROM registry.access.redhat.com/ubi9:latest

RUN dnf -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
RUN dnf config-manager --dump codeready-builder-for-rhel-9-x86_64-rpms | sed -n '/^\[codeready/,$p' | sed '1s/.*\[.*/[crb]/' > /etc/yum.repos.d/crb.repo
