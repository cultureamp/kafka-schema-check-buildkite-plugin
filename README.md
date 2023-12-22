# kafka-schema-check-buildkite-plugin

This is a Buildkite custom plugin enable to be hooked in consumed service for checking if there is any difference of Kafka schema Avro file between your service and our Kafka schema registry

## Example

Add the following lines to your `pipeline.yml`:

```yml
steps:
  - command: "command which parse the content of local Avro schema files"
    # the docker-compose plugin may be used here instead of a command
    plugins:
      - cultureamp/kafka-schema-check#v0.1.0:
```
