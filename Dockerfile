FROM amazonlinux
MAINTAINER Seth Brock <sethabrock@gmail.com>

# Install Dependencies
RUN yum -y update && \
    yum -y install wget tar gzip git glibc libgcc libstdc++ libicu zlib && \
    yum clean all

# Install .NET 8.0
WORKDIR /tmp
RUN wget https://download.visualstudio.microsoft.com/download/pr/5ac82fcb-c260-4c46-b62f-8cde2ddfc625/feb12fc704a476ea2227c57c81d18cdf/dotnet-sdk-8.0.404-linux-arm64.tar.gz
RUN mkdir -p /usr/share/dotnet && \
    tar -xvf dotnet-sdk-8.0.404-linux-arm64.tar.gz -C /usr/share/dotnet && \
    rm dotnet-sdk-8.0.404-linux-arm64.tar.gz

# Set up the environment
ENV PATH="/usr/share/dotnet:$PATH"

# Default working directory
WORKDIR /app

# Download the web app
RUN git clone --depth 1 https://github.com/sethbr11/pdcdonuts.git .
RUN dotnet restore && dotnet build

# Expose the port
EXPOSE 5000
ENV ASPNETCORE_URLS="http://0.0.0.0:5000"

# Pull latest changes from the repository and run the app
CMD git pull origin main && dotnet bin/Debug/net8.0/donuts.dll