# Use an official Elixir runtime as a parent image
FROM elixir:latest

# Update package lists and install necessary packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    nodejs \
    inotify-tools \
    postgresql-client \
    build-essential \
    libasound2 \
    libatk-bridge2.0-0 \
    libgtk-4-1 \
    libnss3 \
    xdg-utils \
    wget \
    unzip

# Install Chrome and ChromeDriver
RUN wget -q -O chrome-linux64.zip https://bit.ly/chrome-linux64-121-0-6167-85 && \
    unzip chrome-linux64.zip && \
    rm chrome-linux64.zip && \
    mkdir -p /opt/chrome && \
    mv chrome-linux64 /opt/chrome/ && \
    ln -s /opt/chrome/chrome-linux64/chrome /usr/local/bin/ && \
    wget -q -O chromedriver-linux64.zip https://bit.ly/chromedriver-linux64-121-0-6167-85 && \
    unzip -j chromedriver-linux64.zip chromedriver-linux64/chromedriver && \
    rm chromedriver-linux64.zip && \
    mv chromedriver /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver

# Install Elixir tools
RUN mix local.rebar --force
RUN mix local.hex --force

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
WORKDIR /app

# Expose the port Crawly is using
EXPOSE 4001

CMD ["sh", "./entrypoint.sh"]
