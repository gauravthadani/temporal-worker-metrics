package metrics

import (
	"crypto/tls"
	"flag"
	"fmt"
	"go.temporal.io/sdk/client"
	"os"
)

// ParseClientOptionFlags parses the given arguments into client options. In
// some cases a failure will be returned as an error, in others the process may
// exit with help info.
func ParseClientOptionFlags(args []string) (client.Options, error) {
	// Parse args
	set := flag.NewFlagSet("hello-world-api-key", flag.ExitOnError)
	targetHost := set.String("target-host", "localhost:7233", "Host:port for the server")
	namespace := set.String("namespace", "default", "Namespace for the server")
	apiKey := set.String("api-key", "", "Optional API key, mutually exclusive with cert/key")

	if err := set.Parse(args); err != nil {
		return client.Options{}, fmt.Errorf("failed parsing args: %w", err)
	}

	if *apiKey == "" {
		*apiKey = os.Getenv("TEMPORAL_CLIENT_API_KEY")
	}

	// Fall back to env vars injected by temporal-worker-controller
	if *targetHost == "localhost:7233" {
		if envHost := os.Getenv("TEMPORAL_ADDRESS"); envHost != "" {
			*targetHost = envHost
		}
	}
	if *namespace == "default" {
		if envNS := os.Getenv("TEMPORAL_NAMESPACE"); envNS != "" {
			*namespace = envNS
		}
	}
	//if *apiKey == "" {
	//	return client.Options{}, fmt.Errorf("-api-key or TEMPORAL_CLIENT_API_KEY env is required required")
	//}

	var opts client.ConnectionOptions

	println("Hello")
	println(*targetHost)
	useTls := !(*targetHost == "localhost:7233" || *targetHost == "temporal:7233" || *targetHost == "temporal-proxy:8443")
	if useTls {
		opts = client.ConnectionOptions{TLS: &tls.Config{}}
	}

	clientOpts := client.Options{
		HostPort:          *targetHost,
		Namespace:         *namespace,
		ConnectionOptions: opts,
	}

	// Only set credentials if API key is provided
	if *apiKey != "" {
		clientOpts.Credentials = client.NewAPIKeyStaticCredentials(*apiKey)
	}

	return clientOpts, nil
}
