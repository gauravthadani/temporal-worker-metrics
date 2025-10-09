package metrics

import (
	"context"
	"fmt"
	"go.temporal.io/sdk/temporal"
	"os"
	"time"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/workflow"
)

type Request struct {
	ReadFile           bool
	ScheduledTimeNanos int64
	FileName           string
}

func Workflow(ctx workflow.Context) error {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: 100 * time.Second,
		RetryPolicy:         &temporal.RetryPolicy{},
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	logger := workflow.GetLogger(ctx)
	logger.Info("Metrics workflow started.")

	//workflow.GetMetricsHandler(ctx).Gauge("my_test_gauge").Update(123.123)
	workflow.GetMetricsHandler(ctx).
		WithTags(map[string]string{
			"workflow-id": workflow.GetInfo(ctx).WorkflowExecution.ID,
		}).Counter("my_test_counter").Inc(1)

	req := &Request{
		ReadFile:           true,
		ScheduledTimeNanos: workflow.Now(ctx).UnixNano(),
		FileName:           "100kb.txt",
		//FileName: "4mb.txt",
	}
	err := workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
	if err != nil {
		logger.Error("Activity failed.", "Error", err)
		return err
	}
	//err = workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
	//if err != nil {
	//	logger.Error("Activity failed.", "Error", err)
	//	return err
	//}
	//err = workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
	//if err != nil {
	//	logger.Error("Activity failed.", "Error", err)
	//	return err
	//}

	//for i := 0; i < 2; i++ {
	//	req := &Request{
	//		ReadFile:           true,
	//		ScheduledTimeNanos: workflow.Now(ctx).UnixNano(),
	//		//FileName:           "100kb.txt",
	//FileName:           "4mb.txt",
	//	}
	//	err := workflow.ExecuteActivity(ctx, Activity, req).Get(ctx, nil)
	//	if err != nil {
	//		logger.Error("Activity failed.", "Error", err)
	//		return err
	//	}
	//}

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
	metricsHandler = recordActivityStart(metricsHandler, "metrics.Activity", req.ScheduledTimeNanos)

	b, err := os.ReadFile(fmt.Sprintf("./resources/%s", req.FileName))
	if err != nil {
		logger.Error("Failed to read file.", "Error", err)
		return Response{}, err
	}
	text := string(b)

	startTime := time.Now()
	defer func() { recordActivityEnd(metricsHandler, startTime, err) }()

	logger.Info("Metrics reported.")
	return Response{Result: text}, err
}
