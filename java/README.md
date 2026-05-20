# Java Hello World (Temporal)

Minimal Temporal Java sample mirroring the layout of the `golang/` module.

## Layout

```
java/
├── build.gradle.kts
├── settings.gradle.kts
├── Dockerfile.worker
├── Dockerfile.starter
└── src/main/java/io/temporal/samples/helloworld/
    ├── HelloWorldWorkflow.java        # @WorkflowInterface
    ├── HelloWorldWorkflowImpl.java
    ├── HelloWorldActivities.java      # @ActivityInterface
    ├── HelloWorldActivitiesImpl.java
    ├── ClientOptionsFactory.java      # env-driven (TEMPORAL_ADDRESS, TEMPORAL_NAMESPACE, TEMPORAL_CLIENT_API_KEY)
    ├── WorkerMain.java                # registers workflow + activity on task queue `hello-world`
    └── StarterMain.java               # starts one workflow, prints the result
```

## Build locally

```
gradle shadowJar starterJar
java -jar build/libs/worker.jar
java -jar build/libs/starter.jar Gaurav
```

## Build Docker images

```
docker build -f Dockerfile.worker  -t temporal-hello-worker:latest .
docker build -f Dockerfile.starter -t temporal-hello-starter:latest .
```

## Environment variables

| Var                        | Default            |
|----------------------------|--------------------|
| `TEMPORAL_ADDRESS`         | `localhost:7233`   |
| `TEMPORAL_NAMESPACE`       | `default`          |
| `TEMPORAL_CLIENT_API_KEY`  | _(unset)_          |

TLS is enabled automatically when `TEMPORAL_ADDRESS` is anything other than `localhost:7233` or `temporal:7233`.

Task queue: `hello-world`.
