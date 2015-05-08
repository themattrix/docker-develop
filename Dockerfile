FROM krallin/ubuntu-tini:14.04

MAINTAINER Matthew Tardiff <mattrix@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get -y install \
        python-software-properties software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN add-apt-repository -y ppa:ultradvorka/ppa

RUN apt-get update \
    && apt-get -y install \
        iptables ca-certificates lxc apt-transport-https \
        tmux git vim htop socat man ruby2.0 ruby2.0-dev \
        bash-completion curl python-pygments vim-youcompleteme \
        python-pip python-dev sshfs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Change the home directory of the root user to /home
ENV HOME /home
ENV USER root
RUN sed -r -i -e 's@^root:.*@root:x:0:0:root:/home:/bin/bash@' /etc/passwd \
    && rm -rf /root

# Store the bash history to its own directory so that we can mount a volume
# to that location and have the history preserved across sessions.
ENV HISTFILE /home/.bash_history/history

# Check out a specific commit - this has the advantage of invalidating the
# cache for this RUN command whenever we want to update this repo.
RUN git clone https://github.com/themattrix/home.git \
    && cd /home \
    && git checkout e871fd5

# Set locale
RUN locale-gen en_US.UTF-8 && /usr/sbin/update-locale LANG=en_US.UTF-8

RUN echo 'source ~/.bashrc' >> /home/.bash_profile

RUN gem2.0 install lolcat && gem2.0 install travis -v 1.7.6 --no-rdoc --no-ri

# docker: "The open-source application container engine"
RUN wget -O /usr/local/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.6.0 \
    && chmod +x /usr/local/bin/docker

# docker-compose: "Define and run complex applications using Docker"
RUN wget -O /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` \
    && chmod +x /usr/local/bin/docker-compose

# docker-machine: "Machine management for a container-centric world"
RUN wget -O /usr/local/bin/docker-machine https://github.com/docker/machine/releases/download/v0.2.0/docker-machine_linux-amd64 \
    && chmod +x /usr/local/bin/docker-machine

# Fuzzy history utility. Seems nicer than hh.
RUN git clone https://github.com/junegunn/fzf.git /home/.fzf \
    && (cd /home/.fzf && git checkout 0.9.11) \
    && (yes | /home/.fzf/install)

RUN wget -O - https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | \
    tar -C /usr/local -xz

# percol: "adds flavor of interactive filtering to the traditional pipe concept of UNIX shell"
# eg: "Useful examples at the command line"
# thefuck: "Magnificent app which corrects your previous console command"
RUN pip install percol==0.1.0 eg==0.1.0 thefuck==1.38

# PathPicker, kinda like percol but better for output containing paths.
RUN git clone https://github.com/facebook/PathPicker.git /home/.pathpicker \
    && cd /home/.pathpicker \
    && git checkout 0.5.5 \
    && chmod +x fpp \
    && ln /home/.pathpicker/fpp /usr/local/bin/fpp

ADD https://raw.githubusercontent.com/junegunn/vim-plug/0.7.1/plug.vim \
    /home/.vim/autoload/plug.vim

# Install vim plugins
RUN vim -u /home/.vim_plug -c 'PlugInstall|q!|q!' > /dev/null
RUN vam install youcompleteme

# Docker-in-docker: https://github.com/jpetazzo/dind
ADD wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

CMD ["wrapdocker"]
