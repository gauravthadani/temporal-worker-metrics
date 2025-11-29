package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/google/uuid"

	"go.temporal.io/sdk/client"

	metrics "github.com/temporalio/samples-go/prometheus"
)

func main() {
	// The client is a heavyweight object that should be created once per process.
	clientOptions, err := metrics.ParseClientOptionFlags(os.Args[1:])
	if err != nil {
		log.Fatalf("Invalid arguments: %v", err)
	}
	c, err := client.Dial(clientOptions)
	if err != nil {
		log.Fatalln("Unable to create client.", err)
	}
	defer c.Close()

	for range 100 {
		go func() {
			startWF(c)
		}()
	}

	// Synchronously wait for the workflow completion.
	//err = we.Get(context.Background(), nil)
	//if err != nil {
	//	log.Fatalln("Unable to wait for workflow completition.", err)
	//}

	time.Sleep(5 * time.Second)

	log.Println("Check metrics at http://localhost:8079/metrics")
}

func startWF(c client.Client) {
	workflowOptions := client.StartWorkflowOptions{
		ID:        "metrics_workflowID_" + uuid.New().String()[0:8],
		TaskQueue: "metrics",
	}

	we, err := c.ExecuteWorkflow(context.Background(), workflowOptions, metrics.Workflow)
	if err != nil {
		log.Fatalln("Unable to execute workflow.", err)
	}

	log.Println("Started workflow.", "WorkflowID", we.GetID(), "RunID", we.GetRunID())
}
