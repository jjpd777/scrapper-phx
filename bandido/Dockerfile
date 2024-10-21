# Use an official Elixir runtime as a parent image
FROM elixir:latest

# Update package lists and install necessary packages
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y nodejs inotify-tools postgresql-client

# Install Elixir tools
RUN mix local.rebar --force
RUN mix local.hex --force

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
WORKDIR /app


CMD ["sh", "./entrypoint.sh"]
