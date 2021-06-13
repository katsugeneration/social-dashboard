FROM python:3.9.5-slim-buster

ENV TF_VERION=0.15.3

RUN apt-get update && apt-get install -y git curl unzip gnupg lsb-release software-properties-common libpq-dev build-essential python-dev ruby ruby-dev

# Install Terraform
RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv && \
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc && \
    $HOME/.tfenv/bin/tfenv install ${TF_VERION} && \
    $HOME/.tfenv/bin/tfenv use ${TF_VERION}

# Install terraform-ls
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install terraform-ls

# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
    apt-get update -y && apt-get install -y google-cloud-sdk

RUN mkdir -p /app/repo
COPY poetry.lock pyproject.toml /app/repo/
COPY docs/Gemfile /app/repo/docs/
WORKDIR /app/repo

# Install jekyll
RUN gem install bundler && bundle install --gemfile docs/Gemfile --path docs/vendor/bundle

# Install poetry
RUN pip install poetry && \
    poetry install --no-interaction --no-ansi