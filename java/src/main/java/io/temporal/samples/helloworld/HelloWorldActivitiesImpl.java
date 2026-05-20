package io.temporal.samples.helloworld;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HelloWorldActivitiesImpl implements HelloWorldActivities {

    private static final Logger logger = LoggerFactory.getLogger(HelloWorldActivitiesImpl.class);

    @Override
    public String composeGreeting(String name) {
        logger.info("Composing greeting for {}", name);
        return "Hello, " + name + "!";
    }
}
