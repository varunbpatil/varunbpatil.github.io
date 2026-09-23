---
title: "Building a Type-Safe Go + React SPA, Part 2: Project Structure"
date: 2026-09-13 10:00:00 +0530
categories: [Software]
tags: [Go, React, Protobufs, Buf connect, go-react-template]
description: An end-to-end type-safe Go + React SPA template
media_subpath: /assets/img/posts/go-react-template-part-2
---

This is a multi-part blog post describing a template for writing end-to-end type-safe apps using Go and React.

You can find the template repository here - [go-react-template](https://github.com/varunbpatil/go-react-template).

For a real production app built using this template, see - [temporal-lens](https://github.com/varunbpatil/temporal-lens).

## Hexagonal Architecture (Ports & Adapters pattern)

This is a very fancy way of saying:

- You define the capabilities of your domain and the functionality it expects from external services using interfaces (what, not how). These are the *Ports*.
- External services, called *Adapters*, implement these *Ports*.
- It should be possible to swap adapters without changing the implementation of the domain.
- `main.go`{: .filepath} is responsible for constructing the adapters and wiring up the domain services.

This is the project structure I use for all my projects. It is a variation of the [project structure](https://github.com/benbjohnson/wtf) recommended by Ben Johnson, the author of BoltDB and the creator of [distributed SQLite](https://fly.io/docs/litefs/) at fly.io. A similar project structure can be used for [Rust projects](https://www.howtocodeit.com/guides/master-hexagonal-architecture-in-rust) as well.

```
.
├── Makefile                   # Task runner
├── buf.yaml                   # Buf module config
├── buf.gen.yaml               # Buf code generation config
│
├── config/                    # App configuration
├── mocks/                     # Generated GoMock implementations
├── shared/                    # Shared code
│
├── protos/                    # Protobuf definitions
│   ├── src/                   # Proto source files
│   └── gen/                   # Generated code
│
├── domains/                   # App domains
│   ├── users/
│   │   ├── models/            # Domain models
│   │   ├── ports/             # Domain ports
│   │   ├── service/           # Domain service
│   │   └── errors.go          # Domain errors
│   │ 
│   └── ...
│
├── inbound/                   # Inbound adapters
│   ├── grpc/
│   ├── http/
│   ├── mcp/
│   └── ...
│
├── outbound/                  # Outbound adapters
│   ├── postgres/
│   └── ...
│
└── ui/                        # React frontend
```

The rest of this blog post is dedicated to exploring each of the individual directories in detail.

## Application Configuration

The library I prefer for parsing environment variables into type-safe Go structs is `github.com/caarlos0/env/v11`.

The following is a realistic production setup from my [temporal-lens](https://github.com/varunbpatil/temporal-lens) project.

```go
package config

import (
	"fmt"
	"net/url"
	"time"

	"github.com/caarlos0/env/v11"
)

type Config struct {
	ReadOnly   bool             `env:"READ_ONLY"`
	Log        LogConfig        `                envPrefix:"LOG_"`
	GRPC       GRPCConfig       `                envPrefix:"GRPC_"`
	HTTP       HTTPConfig       `                envPrefix:"HTTP_"`
	OpenSearch OpenSearchConfig `                envPrefix:"OPENSEARCH_"`
	Temporal   TemporalConfig   `                envPrefix:"TEMPORAL_"`
}

type TemporalConfig struct {
	Namespaces               []string      `env:"NAMESPACES,required"`
	Cloud                    bool          `env:"CLOUD"`
	Account                  string        `env:"ACCOUNT"`
	Endpoint                 string        `env:"ENDPOINT"`
	BaseURL                  url.URL       `env:"BASE_URL,required"`
	APIKey                   string        `env:"API_KEY"`
	TLS                      bool          `env:"TLS"`
	InsecureSkipVerify       bool          `env:"INSECURE_SKIP_VERIFY"`
	ServerName               string        `env:"SERVER_NAME"`
	CAFile                   string        `env:"CA_FILE"`
	ClientCertFile           string        `env:"CLIENT_CERT_FILE"`
	ClientKeyFile            string        `env:"CLIENT_KEY_FILE"`
	ConnPoolSize             int           `env:"CONN_POOL_SIZE"              envDefault:"1"`
	BulkActionsPerSecond     int           `env:"BULK_ACTIONS_PER_SECOND"     envDefault:"8"`
	ListRequestsPerSecond    int           `env:"LIST_REQUESTS_PER_SECOND"    envDefault:"8"`
	HistoryRequestsPerSecond int           `env:"HISTORY_REQUESTS_PER_SECOND" envDefault:"8"`
	IndexPrefix              string        `env:"INDEX_PREFIX"                envDefault:"workflows-"`
	IndexVersion             int           `env:"INDEX_VERSION"               envDefault:"1"`
	ProgressFile             string        `env:"PROGRESS_FILE"`
	RetentionPeriod          time.Duration `env:"RETENTION_PERIOD"            envDefault:"720h"`
	RetentionCron            string        `env:"RETENTION_CRON"              envDefault:"0 0 * * *"`
	DataWorkers              int           `env:"DATA_WORKERS"                envDefault:"8"`
	IndexWorkers             int           `env:"INDEX_WORKERS"               envDefault:"4"`
	IndexBatchSize           int           `env:"INDEX_BATCH_SIZE"            envDefault:"100"`
}

type LogConfig struct {
	Level  string `env:"LEVEL"  envDefault:"info"`
	Format string `env:"FORMAT" envDefault:"text"`
}

type GRPCConfig struct {
	Address string `env:"ADDRESS" envDefault:":50051"`
}

type HTTPConfig struct {
	Address string `env:"ADDRESS" envDefault:":8080"`
}

type OpenSearchConfig struct {
	Addresses          []string `env:"ADDRESSES,required"`
	Username           string   `env:"USERNAME"`
	Password           string   `env:"PASSWORD"`
	APIKey             string   `env:"API_KEY"`
	InsecureSkipVerify bool     `env:"INSECURE_SKIP_VERIFY"`
}

func Parse() (*Config, error) {
	var cfg Config
	if err := env.Parse(&cfg); err != nil {
		return nil, fmt.Errorf("config: %w", err)
	}
	return &cfg, nil
}
```
{: file="config/config.go"}

The top level `Config` struct contains the configs for each of the app domains and some common configuration like logging. The defining feature here is the `envPrefix` struct tag. This basically says any environment variable with that prefix will be parsed into that struct. This allows you to use the same struct definition for multiple instances. For example, if I wanted to have configuration for both self-hosted Temporal and Temporal cloud, I would write:

```go
type Config struct {
	TemporalCloud      TemporalConfig `envPrefix:"TEMPORAL_CLOUD_"`
	TemporalSelfHosted TemporalConfig `envPrefix:"TEMPORAL_SELF_HOSTED_"`
}
```

Any environment variables with the prefix `TEMPORAL_CLOUD_` would be treated as Temporal Cloud configuration and any environment variables with prefix `TEMPORAL_SELF_HOSTED_` would be treated as configuraton for self-hosted Temporal.

## Domains

```
.
├── domains/                   # App domains
│   ├── users/
│   │   ├── models/            # Domain models
│   │   ├── ports/             # Domain ports
│   │   ├── service/           # Domain service
│   │   └── errors.go          # Domain errors
│   │ 
│   └── ...
```

I prefer to have these standard directories and files as below:

- `models` - Contains the domain models.
- `ports` - Contains one or more ports (Go interfaces) and any request/response Go structs needed for those ports. The one mandatory interface is the public API of the current domain itself, which should be the only way other domains interact with this domain.
- `service` - Contains the actual domain logic. The logic should be written using only the ports defined by this domain. It should never call the adapters directly. The adapters that satisfy the ports will be passed in as arguments during service construction in `main.go`{: .filepath}.
- `errors.go` - Defines the errors that can be returned by the public API of this domain. Other domains should depend on only these errors and nothing else. Unlike Rust, Go doesn't have a way to express the actual errors that the public API can return within the API itself. You can and should document the errors returned by the API, but documentation is just that. It can very quickly become stale if you're not fastidious.

One thing worth mentioning is that there is a `ports/errors.go`{: .filepath} as well. These are NOT domain errors. These are just errors that every adapter implementing the domain's ports is expected to return consistently so that the domain logic in `service/`{: .filepath} doesn't have to change depending on which adapter has been configured by `main.go`{: .filepath}.

## Adapters

I prefer to divide them into two groups - `inbound/` and `outbound/`. Inbound adapters are for HTTP, gRPC, MCP, CLI, etc. Outbound adapters are for external services the app uses.

I prefer to name the adapter packages by their dependency. For example, `http`, `grpc`, `mcp`, `postgres`, `opensearch`, `temporal`, etc. This naming convention is intentional, even when they override stdlib package names like `http`. The reason for this is that, all the http related stuff should be confined to the http adapter itself and there should be no reason for code outside the http adapter package to actually import the stdlib http package.

Finally, each domain gets its own subdirectory within the adapter package. For example, `outbound/postgres/users/`{: .filepath}. Code that is common to all domains can reside directly in the adapter package `outbound/postgres/`{: .filepath} and can be imported by all the domain specific packages.

### Parse, Don't Validate

Adapters should define their own types and map (parse) them to the domain types while calling the domain (for inbound adapters) or while returning data back to the domain (for outbound adapters).

For example, the gRPC adapter should parse to/from protobuf types and domain types, the postgres adapter should parse to/from sqlc generated types and domain types. The idea is that the domain type is valid at all times. The domain logic should never have to validate a domain type.

NEVER be tempted to re-use types across boundaries. Sooner or later, you will find that you need a different domain representation than the network representation (maybe you want to hide sensitive fields, etc) or the DB representation.

> Rust has `From`/`Into` and `TryFrom`/`TryInto` traits that your type can implement for exactly this purpose. Unfortunately, Go code will never be as clean as Rust for this and you will have to be content with normal mapping/parsing functions with names like `ProtoToDomain`/`ProtoFromDomain`.
{: .prompt-tip}

## Wiring everything up

This happens in `cmd/.../main.go`{: .filepath}. Its a very small file that constructs the adapters and passes them as arguments to the domain services with the type of their ports.

> This is quite literally plugging adapters into ports.
{: .prompt-info}

This is what it looks like (leaving out some bits for brevity):

```go
func main() {
    os.Exit(run())
}

func run() {
    // Context with signal cancellation
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    onFatal := func(err error) { logger.Error("fatal service error", "error", err); cancel() }

    // Lifecycle manager
    lm := shared.NewLifecycleManager(logger)
    defer func() { cancel(); lm.StopAll(shutdownTimeout) }()

    // Setup users repository
    usersRepo, err := usersRepository.New()
    lm.AddCloser("Users repository", usersRepo)

    // Setup users service
    usersSvc, err := usersService.New(usersRepo)
    lm.Add("Users service", usersSvc)

    // Setup the gRPC adapter
    grpcSrv := grpc.New(cfg.GRPC.Address, logger, onFatal)
    lm.Add("gRPC", grpcSrv)

    // Setup the MCP adapter
	mcpSrv := mcp.New()

    // Setup the HTTP adapter
	httpSrv := http.New(grpcSrv.Handler(), mcp.Handler(mcpSrv), cfg.HTTP.Address, logger, onFatal)
	lm.Add("HTTP", httpSrv)

	// Start all services
	if startErr := lm.StartAll(ctx); startErr != nil {
		return 1
	}

	// Shutdown gracefully
	<-ctx.Done()
	return 0
}
```
{: file="cmd/service/main.go"}

Curious folk might ask why `main()` needs to call `run()`? The reason is that you cannot have deferred functions in the same function as `os.Exit()`. Those deferred functions will not run. If you want the deferred functions to run, you have to separate it out into a function that does not call `os.Exit()`.

Another nice thing you will notice about the naming convention is that all the constructors (adapters and domain services) are named `New`. There is no need to come up with names. The package name already namespaces it. Also notice how `http` is the adapter package, not the stdlib package.

Without question, the most important part of `main.go`{: .filepath} is the graceful shutdown handling. This is managed by the aptly named [Lifecycle Manager](https://github.com/varunbpatil/go-react-template/blob/main/shared/lifecycle.go). It provides two methods to register your services:

- `AddCloser()` for simple services where resources are allocated during construction and need to be released during shutdown.
- `Add()` for long-running services (known as daemon's) which need to be started separately after construction and need to be stopped during shutdown.

Services are started in the order of registration and shutdown in the reverse order.

### Handling Inter-dependencies

One common pattern that I often encounter is real production apps is a dependency between an adapter and a domain service.

Lets say we have a `users` domain whose service exposes an adapter-agnostic schema. This schema is required by the UI to build the form fields and for form validation. It is also required by the persistence layer to persist users. This invariably means that the repository adapter needs access to the schema that only the domain service can provide. But, the domain service itself depends on the repository adapter for its logic.

Often, the adapter only needs a very specific thing from the service. In this case, the adapter just needs the schema from the service. This can be handled in the following way:

```go
func run() {
    var err error
    var usersSvc *usersService.Service

    // Setup users repository
    usersRepo, err := usersRepository.New(Params{
        schema: func() shared.Schema { return usersSvc.Schema() }
    })

    // Setup users service
    usersSvc, err = usersService.New(usersRepo)
}
```
{: file="cmd/service/main.go"}

`usersRepository.New()` takes a closure that resolves to the schema at some later point when the users service has been constructed.

## Integration Tests

I like putting all integration tests under `integration_tests/` at the project root. All integration test files have the following go build tags:

```go
//go:build integration || all
```

which means they only run when `go test -tags=integration` is specified. This is necessary because integration tests can be expensive to run and you don't want to run them everytime normal unit tests are run. The `all` build tag is there so that IDEs like VSCode can still provide diagnostics on these integration test files with a simple configuration like [this](https://github.com/varunbpatil/go-react-template/blob/main/.vscode/settings.json#L5-L7).
