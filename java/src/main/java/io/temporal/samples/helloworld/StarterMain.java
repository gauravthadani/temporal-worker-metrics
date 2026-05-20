package io.temporal.samples.helloworld;

import io.temporal.api.common.v1.WorkflowExecution;
import io.temporal.client.WorkflowClient;
import io.temporal.client.WorkflowClientOptions;
import io.temporal.client.WorkflowOptions;
import io.temporal.serviceclient.WorkflowServiceStubs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.UUID;

public final class StarterMain {

    private static final Logger logger = LoggerFactory.getLogger(StarterMain.class);

    public static void main(String[] args) {
        String name = args.length > 0 ? args[0] : "World";

        WorkflowServiceStubs service =
                WorkflowServiceStubs.newServiceStubs(
                        ClientOptionsFactory.serviceStubsBuilder().build());

        WorkflowClient client =
                WorkflowClient.newInstance(
                        service,
                        WorkflowClientOptions.newBuilder()
                                .setNamespace(ClientOptionsFactory.namespace())
                                .build());

        String workflowId = "hello-world_" + UUID.randomUUID().toString().substring(0, 8);

        HelloWorldWorkflow workflow =
                client.newWorkflowStub(
                        HelloWorldWorkflow.class,
                        WorkflowOptions.newBuilder()
                                .setTaskQueue(ClientOptionsFactory.TASK_QUEUE)
                                .setWorkflowId(workflowId)
                                .build());

        // Async start — the workflow waits up to 4 weeks for a `proceed` signal
        // and then continues-as-new, so it never returns a synchronous result.
        WorkflowExecution execution = WorkflowClient.start(workflow::sayHello, name);
        logger.info(
                "Started workflow id={} runId={} for name '{}'",
                execution.getWorkflowId(),
                execution.getRunId(),
                name);
    }
}
