FROM debian:buster-slim

ENV TF_VERION=0.15.3

RUN apt-get update && apt-get install -y git curl unzip gnupg lsb-release software-properties-common

# Install Terraform
RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv && \
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc && \
    $HOME/.tfenv/bin/tfenv install ${TF_VERION} && \
    $HOME/.tfenv/bin/tfenv use ${TF_VERION}

# Install terraform-ls
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install terraform-ls
