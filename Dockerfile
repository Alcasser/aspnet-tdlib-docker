FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env

WORKDIR /app

RUN apt-get update && apt-get -y upgrade &&\
    apt-get -y install make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev &&\
    git clone https://github.com/tdlib/td.git &&\
    cd td &&\
    rm -rf build &&\
    mkdir build &&\
    cd build &&\
    CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang CXX=/usr/bin/clang++ cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=../tdlib .. &&\
    cmake --build . --target install &&\
    cd .. &&\
    cd ..

RUN mkdir out
RUN mv td/tdlib/lib/* out

RUN rm -r td

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0

RUN apt-get update && apt-get -y upgrade &&\
    apt-get -y install libc++1

WORKDIR /app

COPY --from=build-env /app/out .

ENTRYPOINT ["dotnet", "yourapp.dll"]
