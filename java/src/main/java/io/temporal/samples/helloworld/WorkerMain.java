package io.temporal.samples.helloworld;

import io.temporal.client.WorkflowClient;
import io.temporal.client.WorkflowClientOptions;
import io.temporal.common.VersioningBehavior;
import io.temporal.common.WorkerDeploymentVersion;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerDeploymentOptions;
import io.temporal.worker.WorkerFactory;
import io.temporal.worker.WorkerOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class WorkerMain {

    private static final Logger logger = LoggerFactory.getLogger(WorkerMain.class);

    public static void main(String[] args) {
        WorkflowServiceStubs service =
                WorkflowServiceStubs.newServiceStubs(
                        ClientOptionsFactory.serviceStubsBuilder().build());

        WorkflowClient client =
                WorkflowClient.newInstance(
                        service,
                        WorkflowClientOptions.newBuilder()
                                .setNamespace(ClientOptionsFactory.namespace())
                                .build());

        WorkerFactory factory = WorkerFactory.newInstance(client);

        String deploymentName = ClientOptionsFactory.deploymentName();
        String buildId = ClientOptionsFactory.workerBuildId();

        WorkerDeploymentOptions.Builder deploymentBuilder = WorkerDeploymentOptions.newBuilder();
        if (deploymentName != null && buildId != null) {
            deploymentBuilder
                    .setUseVersioning(true)
                    .setVersion(new WorkerDeploymentVersion(deploymentName, buildId))
                    .setDefaultVersioningBehavior(VersioningBehavior.PINNED);
        }

        WorkerOptions workerOptions = WorkerOptions.newBuilder()
                .setDeploymentOptions(deploymentBuilder.build())
                .build();

        Worker worker = factory.newWorker(ClientOptionsFactory.TASK_QUEUE, workerOptions);

        worker.registerWorkflowImplementationTypes(HelloWorldWorkflowImpl.class);
        worker.registerActivitiesImplementations(new HelloWorldActivitiesImpl());

        logger.info(
                "Starting worker against {} (namespace {}) on task queue {} (deployment={}, buildId={})",
                ClientOptionsFactory.targetHost(),
                ClientOptionsFactory.namespace(),
                ClientOptionsFactory.TASK_QUEUE,
                deploymentName,
                buildId);

        factory.start();
    }
}
