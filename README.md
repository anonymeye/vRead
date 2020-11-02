
## Status
web app using Vapor and postgres ... the work is **In Progres**

## Usage
to build the project

```
vapor build 

vaport xcode -y
```

other useful commands for the database
```
docker stop postgres

docker rm postgres

docker run --name postgres -e POSTGRES_DB=vapor 
-e POSTGRES_USER=vapor -e POSTGRES_PASSWORD=password  -p 5432:5432 -d postgres
```

<p align="center">
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1">
    </a>
</p>
