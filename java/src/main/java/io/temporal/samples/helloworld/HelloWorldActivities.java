package io.temporal.samples.helloworld;

import io.temporal.activity.ActivityInterface;

@ActivityInterface
public interface HelloWorldActivities {

    String composeGreeting(String name);
}
