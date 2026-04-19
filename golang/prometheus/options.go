package metrics

import (
	"crypto/tls"
	"flag"
	"fmt"
	"os"

	"go.temporal.io/sdk/client"
)

func ParseClientOptionFlags(args []string) (client.Options, error) {
	set := flag.NewFlagSet("worker", flag.ExitOnError)
	targetHost := set.String("target-host", "localhost:7233", "Host:port for the server")
	namespace := set.String("namespace", "default", "Temporal namespace")
	apiKey := set.String("api-key", "", "API key, mutually exclusive with cert/key")
	tlsCertPath := set.String("tls-cert-path", "", "Path to client TLS certificate (mTLS)")
	tlsKeyPath := set.String("tls-key-path", "", "Path to client TLS key (mTLS)")

	if err := set.Parse(args); err != nil {
		return client.Options{}, fmt.Errorf("failed parsing args: %w", err)
	}

	if *apiKey == "" {
		*apiKey = os.Getenv("TEMPORAL_CLIENT_API_KEY")
	}

	var connOpts client.ConnectionOptions

	useTLS := !(*targetHost == "localhost:7233" || *targetHost == "temporal:7233")
	if useTLS {
		tlsCfg := &tls.Config{}

		if *tlsCertPath != "" && *tlsKeyPath != "" {
			cert, err := tls.LoadX509KeyPair(*tlsCertPath, *tlsKeyPath)
			if err != nil {
				return client.Options{}, fmt.Errorf("failed loading mTLS cert/key: %w", err)
			}
			tlsCfg.Certificates = []tls.Certificate{cert}
		}

		connOpts = client.ConnectionOptions{TLS: tlsCfg}
	}

	clientOpts := client.Options{
		HostPort:          *targetHost,
		Namespace:         *namespace,
		ConnectionOptions: connOpts,
	}

	if *apiKey != "" {
		clientOpts.Credentials = client.NewAPIKeyStaticCredentials(*apiKey)
	}

	return clientOpts, nil
}
