package io.temporal.samples.helloworld;

import io.temporal.activity.ActivityOptions;
import io.temporal.common.InitialVersioningBehavior;
import io.temporal.common.RetryOptions;
import io.temporal.workflow.ContinueAsNewOptions;
import io.temporal.workflow.Workflow;
import org.slf4j.Logger;

import java.time.Duration;

public class HelloWorldWorkflowImpl implements HelloWorldWorkflow {

    private static final Logger logger = Workflow.getLogger(HelloWorldWorkflowImpl.class);
    private static final Duration WAIT_DURATION = Duration.ofDays(28);

    private final HelloWorldActivities activities =
            Workflow.newActivityStub(
                    HelloWorldActivities.class,
                    ActivityOptions.newBuilder()
                            .setStartToCloseTimeout(Duration.ofSeconds(30))
                            .setRetryOptions(
                                    RetryOptions.newBuilder()
                                            .setMaximumAttempts(3)
                                            .build())
                            .build());

    private boolean proceed = false;

    @Override
    public String sayHello(String name) {
        logger.info("HelloWorld workflow started for {}", name);

        String greeting = activities.composeGreeting(name);
        logger.info("Activity completed: {}", greeting);

        greeting = activities.composeGreeting(name);
        logger.info("Activity completed: {}", greeting);

        boolean signalled = Workflow.await(WAIT_DURATION, () -> proceed);
        logger.info(
                "Wait completed (signalled={}). Continuing as new for {}.", signalled, name);

        Workflow.continueAsNew(ContinueAsNewOptions
                .newBuilder()
                .setInitialVersioningBehavior(InitialVersioningBehavior.AUTO_UPGRADE)
                .build());
        // Unreachable: continueAsNew throws to terminate this run.
        return greeting;
    }

    @Override
    public void proceed() {
        logger.info("Received proceed signal.");
        this.proceed = true;
    }
}
