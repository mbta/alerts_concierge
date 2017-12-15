### Getting Started
To run a production-like environment locally with docker, run the following commands:

```
docker-compose build
docker-compose run app mix ecto.migrate
docker-compose up
```

The application will be available at [http://localhost](http://localhost)

### TODO
- encapsulate environment variables
