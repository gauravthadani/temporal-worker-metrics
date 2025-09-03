package metrics

import (
	"context"
	"os"
	"time"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/workflow"
)

type Request struct {
	readFile           bool
	scheduledTimeNanos int64
}

func Workflow(ctx workflow.Context) error {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	logger := workflow.GetLogger(ctx)
	logger.Info("Metrics workflow started.")

	req := &Request{
		readFile:           true,
		scheduledTimeNanos: workflow.Now(ctx).UnixNano(),
	}
	err := workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
	if err != nil {
		logger.Error("Activity failed.", "Error", err)
		return err
	}

	for i := 0; i < 5; i++ {
		req := &Request{
			readFile:           true,
			scheduledTimeNanos: workflow.Now(ctx).UnixNano(),
		}
		err := workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
		if err != nil {
			logger.Error("Activity failed.", "Error", err)
			return err
		}
	}

	logger.Info("Metrics workflow completed.")
	return nil
}

type Response struct {
	Result string
}

func Activity(ctx context.Context, req Request) (Response, error) {
	logger := activity.GetLogger(ctx)

	var err error
	metricsHandler := activity.GetMetricsHandler(ctx)
	metricsHandler = recordActivityStart(metricsHandler, "metrics.Activity", req.scheduledTimeNanos)

	//var text string
	//if req.readFile {
	b, _ := os.ReadFile("./resources/100kb.txt")
	text := string(b)

	//}
	startTime := time.Now()
	defer func() { recordActivityEnd(metricsHandler, startTime, err) }()

	time.Sleep(time.Second)
	logger.Info("Metrics reported.")
	return Response{Result: text}, err
}
