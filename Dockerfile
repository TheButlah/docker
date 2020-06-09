# By default, use latest ubuntu. Builds requiring a different base can be given via `BASE_IMAGE` arg
# NOTE: CUDA base image at nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
ARG BASE_IMAGE=ubuntu:latest
FROM ${BASE_IMAGE} AS zsh-setup

# Pass in the username we will run as instead of root.
ARG USERNAME=me
ENV USERNAME=$(whoami)

# We check to see if sudo is installed, and if not, install it. This simplifies using
# in cases where we are not root, but do have sudo. This way the rest of the dockerfile
# can just use sudo in both cases
RUN if ! [ "$(command -v sudo)" ]; then \
    echo "Sudo command isn't installed. Attempting to install. This may fail if we are not root." \
    && apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/* \
    && echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;\
fi

# Make sure none of these things try to get all interactive on us.
# See https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Important for many programs, including python, to work properly
RUN sudo apt-get update && sudo apt-get install -y apt-utils locales && sudo rm -rf /var/lib/apt/lists/*
RUN sudo locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN sudo dpkg-reconfigure locales

RUN sudo apt-get update && sudo apt-get install -y tzdata \
    && echo "US/Eastern" | sudo tee /etc/timezone \
    && sudo dpkg-reconfigure tzdata \
    && sudo rm -rf /var/lib/apt/lists/*

# Install zsh and oh-my-zsh
RUN sudo apt-get update && sudo apt-get install -y \
    curl \
    git \
    zsh \
    && sudo rm -rf /var/lib/apt/lists/*

RUN chsh -s /usr/bin/zsh

# Install zsh plugins
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
COPY --chown=${USERNAME}:${USERNAME} .zshrc .p10k.zsh /home/${USERNAME}/

# Let zsh fetch whatever it needs the first time
RUN [ "/usr/bin/zsh", "-c", "echo Ran zsh for first time!" ]
ENTRYPOINT [ "/usr/bin/zsh" ]
