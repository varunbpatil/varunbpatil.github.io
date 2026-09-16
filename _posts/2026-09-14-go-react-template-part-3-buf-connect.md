---
title: "Building a Type-Safe Go + React SPA, Part 3: Buf, Connect, and Connect Query"
date: 2026-09-14 10:00:00 +0530
categories: [Software]
tags: [Go, React, Protobufs, Buf connect, go-react-template]
description: An end-to-end type-safe Go + React SPA template
media_subpath: /assets/img/posts/go-react-template-part-3
---

This is a multi-part blog post describing a template for writing end-to-end type-safe apps using Go and React.

You can find the template repository here - [go-react-template](https://github.com/varunbpatil/go-react-template).

For a real production app built using this template, see - [temporal-lens](https://github.com/varunbpatil/temporal-lens).

## Buf & Connect

In the [previous post]({% post_url 2026-09-13-go-react-template-part-2-project-structure %}), I showed the gRPC adapter in the `inbound/` directory. This post explains the contract that adapter implements and how the same contract reaches the React application.

[Protocol Buffers](https://protobuf.dev) are the source of truth for the API. They describe messages and RPC methods in one small, language-neutral file:

```proto
syntax = "proto3";

package go_react_template.users.v1;

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  User user = 1;
}

message User {
  string name = 1;
}
```
{: file="protos/src/go_react_template/users/v1/users.proto"}

The template uses [Buf](https://buf.build) to lint, format, check backwards compatibility, and generate code from these files. It is a much nicer interface to `protoc`, particularly once a project grows beyond one proto file.

`buf.yaml`{: .filepath} declares the proto source directory as a module and enables Buf's standard lint rules:

```yaml
version: v2

modules:
  - path: protos/src
    name: github.com/varunbpatil/go-react-template

lint:
  use:
    - STANDARD

breaking:
  use:
    - FILE
```
{: file="buf.yaml"}

The `FILE` breaking check compares the current proto files to `main`. This catches accidental API breaks such as changing a field number or removing an RPC before they are released. The useful commands are deliberately unsurprising:

```sh
make proto/fmt
make proto/lint
make proto/breaking
make proto/generate
```

### protoc plugins

Here is the complete plugin configuration:

```yaml
version: v2
clean: true

managed:
  enabled: true
  override:
    - file_option: go_package_prefix
      value: github.com/varunbpatil/go-react-template/protos/gen

plugins:
  - local: protoc-gen-go
    out: protos/gen
    opt:
      - paths=source_relative

  - local: protoc-gen-connect-go
    out: protos/gen
    opt:
      - paths=source_relative

  - local: protoc-gen-es
    out: ui/src/gen
    opt:
      - target=ts

  - local: protoc-gen-connect-query
    out: ui/src/gen
    opt:
      - target=ts
```
{: file="buf.gen.yaml"}

`clean: true` removes generated files which no longer correspond to a proto file. The managed `go_package_prefix` avoids repeating a Go import path in every `.proto` file. `paths=source_relative` keeps the generated directory layout identical to `protos/src/`, which makes generated code easy to find.

There are four `protoc` plugins in use:

- `protoc-gen-go` generates Go protobuf messages, reflection metadata, and the `UserService` service descriptor.
- `protoc-gen-connect-go` generates the type-safe Go `UserServiceHandler` interface, a client, route constants, and `NewUserServiceHandler`.
- `protoc-gen-es` generates TypeScript message types, message schemas, and service descriptors for the browser.
- `protoc-gen-connect-query` generates a small TypeScript module that exports each RPC method descriptor in the shape Connect Query expects.

The tools are project dependencies, rather than a list of things each developer must install by hand:

```toml
"buf" = "1.72.0"
"protoc-gen-go" = "1.36.12"
"protoc-gen-connect-go" = "1.20.0"
"npm:@bufbuild/protoc-gen-es" = "2.14.1"
"npm:@connectrpc/protoc-gen-connect-query" = "2.3.1"
```
{: file=".mise.toml"}

For the service above, Connect Query generates exactly this useful bridge:

```ts
import { UserService } from "./users_pb";

export const getUser = UserService.method.getUser;
```
{: file="ui/src/gen/go_react_template/users/v1/users-UserService_connectquery.ts"}

It may look almost too small to be worthwhile. Its value is that `getUser` retains the fully typed protobuf input and output descriptors. React code does not spell endpoint URLs, hand-write a JSON type, or duplicate a cache key.

## Connect is HTTP, so there is no grpc-gateway

Traditional browser gRPC setups often add [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway). It generates a REST/JSON facade in front of a gRPC service. That requires HTTP annotations in the proto definitions, another `protoc` plugin, generated gateway registration, and maintaining two API styles. It is unnecessary for this SPA.

That does **not** mean choosing Connect rules out a public REST API. [Vanguard Go](https://github.com/connectrpc/vanguard-go) can wrap Connect handlers and transcode REST/JSON requests to the same RPC implementation using the standard `google.api.http` annotations. Unlike grpc-gateway, it performs the translation in the Go HTTP server and does not require a separate generated gateway. Vanguard is currently alpha, so assess its stability and feature fit before choosing it for a production public API. The template simply has no REST routes to expose, so it does not add either layer.

[Connect](https://connectrpc.com) is an RPC protocol designed for the web. A Connect-Go handler is an ordinary `net/http` handler, while the browser client uses `fetch`. The generated handler supports Connect, gRPC, and gRPC-Web, with protobuf and JSON codecs. One implementation can therefore serve a native gRPC client and the web application.

The Go adapter is just a typed bridge from the domain to the generated handler:

```go
func Register(server grpc.Registrar, handler usersv1connect.UserServiceHandler) {
	path, httpHandler := usersv1connect.NewUserServiceHandler(
		handler,
		server.HandlerOptions()...,
	)
	server.Handle(path, httpHandler)
}

func (h *Handler) GetUser(
	ctx context.Context,
	req *connect.Request[usersv1.GetUserRequest],
) (*connect.Response[usersv1.GetUserResponse], error) {
	user, err := h.svc.GetUser(ctx, req.Msg.GetId())
	if errors.Is(err, users.ErrUserNotFound) {
		return nil, connect.NewError(connect.CodeNotFound, err)
	}
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&usersv1.GetUserResponse{User: userToProto(user)}), nil
}
```
{: file="inbound/grpc/users/handler.go"}

Despite the package name being `grpc`, this adapter does not need a separate REST/HTTP adapter wrapper. `NewUserServiceHandler` returns an HTTP handler. The HTTP server mounts all Connect routes below `/api` and serves the embedded React SPA at `/`:

```go
router.Route("/api", func(router chi.Router) {
	router.Handle("/", http.NotFoundHandler())
	router.Handle("/*", http.StripPrefix("/api", api))
})

router.Get("/*", ui.ServeHTTP)
router.Head("/*", ui.ServeHTTP)
```
{: file="inbound/http/server.go"}

Consequently, a browser request reaches `/api/go_react_template.users.v1.UserService/GetUser`; Connect decodes it, invokes the same Go handler a gRPC client would have invoked, and encodes the response.

The trade-off is intentional: Connect is excellent for a first-party TypeScript application and typed service clients. If third parties require conventional REST APIs, use Vanguard Go or grpc-gateway.

## React, Connect Query, and TanStack Query

The frontend creates one Connect transport and provides it to Connect Query. The transport points at `/api`, so development uses Vite's proxy and production uses the same origin as the embedded UI.

```tsx
const queryClient = new QueryClient();

const transport = createConnectTransport({
  baseUrl: `${window.location.origin}/api`,
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <TransportProvider transport={transport}>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </TransportProvider>
  </StrictMode>,
);
```
{: file="ui/src/main.tsx"}

[Connect Query](https://github.com/connectrpc/connect-query-es) is built on [TanStack Query](https://tanstack.com/query). It supplies the RPC-aware query function and query key; TanStack Query supplies caching, request de-duplication, loading and error state, retries, invalidation, and mutations. A normal component query is therefore very small:

```tsx
import { useQuery } from "@connectrpc/connect-query";
import { getUser } from "@/gen/go_react_template/users/v1/users-UserService_connectquery";

function UserName({ id }: { id: string }) {
  const { data, error, isPending } = useQuery(getUser, { id });

  if (isPending) return <p>Loading...</p>;
  if (error) return <p>{error.message}</p>;
  return <h1>{data.user?.name}</h1>;
}
```

The `{ id }` argument is checked against `GetUserRequest`. `data.user` is checked against `GetUserResponse`. Rename a proto field, regenerate, and every affected caller becomes a TypeScript error. There is no separate REST client or manually maintained request/response interface.

There is no special TanStack Router integration required. TanStack Router owns navigation and URL state; Connect Query owns server state. The `TransportProvider` already supplies the transport, and Connect Query creates the TanStack Query key from the generated method descriptor and request. A route component can simply call `useQuery` as above.

Mutations are equally direct. Suppose the user service has a `CreateUser` RPC:

```proto
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}

message CreateUserRequest { string name = 1; }
message CreateUserResponse { User user = 1; }
```

After `make proto/generate`, the generated Connect Query file exports `createUser`. A component can use it directly:

```tsx
import { useMutation } from "@connectrpc/connect-query";
import { createUser } from "@/gen/go_react_template/users/v1/users-UserService_connectquery";

function CreateUserButton() {
  const create = useMutation(createUser, {
    onSuccess: (response) => {
      console.log(`Created ${response.user?.name}`);
    },
  });

  return (
    <button onClick={() => create.mutate({ name: "Ada" })} disabled={create.isPending}>
      Create user
    </button>
  );
}
```

`useMutation` infers the input to `mutate()` and the response in `onSuccess`. If a successful mutation affects a visible query, refetch or invalidate that query; no additional router plumbing is involved.

The overall workflow is pleasantly boring - change the proto contract, run `make proto/generate`, implement the generated Go handler method, and use the generated method descriptor in React. The compiler then points to every server and UI call site that needs to change. That is the end-to-end type safety this template is trying to provide.
