# syntax=docker/dockerfile:1

# Define a versão do Ruby
ARG RUBY_VERSION=3.3.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Diretório da aplicação Rails
WORKDIR /rails

# Instala pacotes essenciais
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libvips \
    postgresql-client nodejs npm ffmpeg && \
    echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configuração do ambiente de desenvolvimento
ENV RAILS_ENV="development"    

# Build stage para instalar gems
FROM base AS build

COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copia o código da aplicação
COPY . .

# Final stage
FROM base

# Copia as gems instaladas no build
COPY --from=build /usr/local/bundle /usr/local/bundle
# Copia o código da aplicação
COPY --from=build /rails /rails

# Precompile assets
RUN bundle exec rails assets:precompile

# Configura o ponto de entrada
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Comando default
CMD ["rails", "server", "-b", "0.0.0.0"]