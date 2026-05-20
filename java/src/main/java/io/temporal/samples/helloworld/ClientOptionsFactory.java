package io.temporal.samples.helloworld;

import io.temporal.serviceclient.WorkflowServiceStubsOptions;

public final class ClientOptionsFactory {

    public static final String DEFAULT_TARGET = "localhost:7233";
    public static final String DEFAULT_NAMESPACE = "default";
    public static final String TASK_QUEUE = "hello-world";

    private ClientOptionsFactory() {}

    public static String targetHost() {
        String address = System.getenv("TEMPORAL_ADDRESS");
        return (address == null || address.isBlank()) ? DEFAULT_TARGET : address;
    }

    public static String namespace() {
        String ns = System.getenv("TEMPORAL_NAMESPACE");
        return (ns == null || ns.isBlank()) ? DEFAULT_NAMESPACE : ns;
    }

    public static String apiKey() {
        String key = System.getenv("TEMPORAL_CLIENT_API_KEY");
        return (key == null || key.isBlank()) ? null : key;
    }

    public static String deploymentName() {
        String name = System.getenv("TEMPORAL_DEPLOYMENT_NAME");
        return (name == null || name.isBlank()) ? null : name;
    }

    public static String workerBuildId() {
        String id = System.getenv("TEMPORAL_WORKER_BUILD_ID");
        return (id == null || id.isBlank()) ? null : id;
    }

    public static WorkflowServiceStubsOptions.Builder serviceStubsBuilder() {
        String target = targetHost();
        WorkflowServiceStubsOptions.Builder builder =
                WorkflowServiceStubsOptions.newBuilder().setTarget(target);

        boolean useTls = !(target.equals(DEFAULT_TARGET) || target.equals("temporal:7233"));
        if (useTls) {
            builder.setEnableHttps(true);
        }

        String key = apiKey();
        if (key != null) {
            builder.addApiKey(() -> key);
        }
        return builder;
    }
}
