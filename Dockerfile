# By default, use latest ubuntu. Builds requiring a different base can be given via `BASE_IMAGE` arg
# NOTE: CUDA base image at nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
ARG BASE_IMAGE=ubuntu:latest
FROM ${BASE_IMAGE} AS zsh-setup

# Pass in the username we will run as instead of root.
ARG USERNAME=me
ENV USERNAME=${USERNAME}

# Make sure none of these things try to get all interactive on us.
# See https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Important for many programs, including python, to work properly
RUN apt-get update && apt-get install -y apt-utils locales && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN dpkg-reconfigure locales

RUN apt-get update && apt-get install -y tzdata \
    && echo "US/Eastern" | tee /etc/timezone \
    && dpkg-reconfigure tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install the stuff needed to get things to function well out of the box
RUN apt-get update && apt-get install -y \
    man \
    sudo \
    lsb-release \
    software-properties-common \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install zsh and oh-my-zsh
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Allow users with sudo permission to run sudo without password
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up user and group
RUN echo "USERNAME: ${USERNAME}"
RUN groupadd ${USERNAME} && \
    useradd -m -r -s /usr/bin/zsh -g ${USERNAME} -G sudo ${USERNAME}
RUN touch /home/${USERNAME}/.zshrc
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Fix issue where gpg keys try to use IPV6 but docker only has IPV4, occurs
# nondeterministically on `apt-key adv`. Provide `--homedir ~/.gnupg` to all such commands.
# See https://github.com/f-secure-foundry/usbarmory-debian-base_image/issues/9#issuecomment-451635505
RUN mkdir ~/.gnupg && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# Install zsh plugins
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
COPY --chown=${USERNAME}:${USERNAME} .zshrc .p10k.zsh /home/${USERNAME}/

# Let zsh fetch whatever it needs the first time
RUN [ "/usr/bin/zsh", "-c", "echo Ran zsh for first time!" ]
ENTRYPOINT [ "/usr/bin/zsh" ]

