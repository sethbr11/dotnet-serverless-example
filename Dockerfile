FROM amazonlinux
LABEL maintainer="sethabrock@gmail.com"

# Install Dependencies
RUN yum -y update && \
    yum -y install wget tar gzip git glibc libgcc libstdc++ libicu zlib && \
    yum clean all

# Set up the environment for multiple architectures
WORKDIR /tmp
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        FILENAME="dotnet-sdk-8.0.404-linux-x64.tar.gz"; \
        wget https://download.visualstudio.microsoft.com/download/pr/4e3b04aa-c015-4e06-a42e-05f9f3c54ed2/74d1bb68e330eea13ecfc47f7cf9aeb7/dotnet-sdk-8.0.404-linux-x64.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        FILENAME="dotnet-sdk-8.0.404-linux-arm64.tar.gz"; \
        wget https://download.visualstudio.microsoft.com/download/pr/5ac82fcb-c260-4c46-b62f-8cde2ddfc625/feb12fc704a476ea2227c57c81d18cdf/dotnet-sdk-8.0.404-linux-arm64.tar.gz; \
    fi && \
    mkdir -p /usr/share/dotnet && \
    tar -xvf $FILENAME -C /usr/share/dotnet && \
    rm $FILENAME

# Set up the environment
ENV PATH="/usr/share/dotnet:$PATH"

# Default working directory
WORKDIR /app

# Download the web app
RUN git clone --depth 1 https://github.com/sethbr11/pdcdonuts.git .
RUN dotnet restore && dotnet build

# Expose the port (change from 5000 to 80)
EXPOSE 80

# Set ASP.NET Core to use port 80
ENV ASPNETCORE_URLS="http://0.0.0.0:80"

# Pull latest changes from the repository and run the app
CMD git pull origin main && dotnet bin/Debug/net8.0/donuts.dll
