FROM julia:latest

LABEL author="Péter Molnár"
LABEL maintainer="peter@molnar.ai"

ENV PROJECT_DIR=/opt/work 
ENV INSTALL_DIR=/opt/install 

#install required packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    apt-utils gcc g++ openssh-server cmake build-essential \
    gdb gdbserver rsync vim locales
RUN apt-get install -y bzip2 wget gnupg dirmngr apt-transport-https \
	ca-certificates tmux && \
    apt-get clean

# install Jupyter
RUN apt install python3 python3-pip python3-full -y
RUN apt install git -y
#RUN pip install -U virtualenv
#RUN pip3 install jupyterlab

#setup ssh
RUN mkdir -p /var/run/sshd && \
    echo 'root:root_pwd' |chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh

#remove leftovers
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose 22 for ssh server. 7777 for gdb server.
EXPOSE 22 8888 9346

# Install 
RUN mkdir -p ${INSTALL_DIR}
COPY ./install.jl ./install_python.sh ./requirements.txt ./jupyterlab.sh ${INSTALL_DIR}
RUN ${INSTALL_DIR}/install_python.sh 
RUN /usr/local/julia/bin/julia ${INSTALL_DIR}/install.jl
# RUN mkdir -p ${PROJECT_DIR}/src
# COPY "../src" ${PROJECT_DIR}/src


WORKDIR ${PROJECT_DIR}

# ENTRYPOINT [ "/bin/bash" ]
CMD ${INSTALL_DIR}/jupyterlab.sh


