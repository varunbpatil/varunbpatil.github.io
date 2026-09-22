---
title: "protoc-gen-go-errors: Typed Go Errors, Generated from Your Protobufs"
date: 2026-09-21 10:00:00 +0530
categories: [Software]
tags: [Go, Protobufs, Buf, Error handling, protoc-gen-go-errors]
description: A protoc plugin that generates type-safe Go errors from your proto definitions
---

You can find the plugin repository here - [protoc-gen-go-errors](https://github.com/varunbpatil/protoc-gen-go-errors).

The protobuf module (the `(errors.display)` option definition) is published on the Buf Schema Registry - [buf.build/varunbpatil-oss/protoc-gen-go-errors](https://buf.build/varunbpatil-oss/protoc-gen-go-errors).

## The error problem

Go errors are just `error` interfaces. Which is nice, until you want a domain error with a structured shape: a few fields, a readable message, maybe another error to unwrap. That is usually a hand-written struct, a hand-written `Error() string`, a hand-written `Unwrap()`, and vigilance to keep the message format in sync with the fields.

Rust solves this elegantly with [thiserror](https://github.com/dtolnay/thiserror) - declare the error shape, derive the implementations, move on. Go has no derive macros, but it **does** have a code generator already sitting in most gRPC stacks: the protoc plugins. If your API contract already lives in `.proto` files, the errors might as well live there too.

The part worth dwelling on is visibility. In Rust, errors are an enum and the type system makes you confront every variant - a function signature like `Result<T, CreateUserError>` tells you exactly the ways it can fail, and `match` refuses to let you forget one. Go's `error` interface offers none of that: a function can return anything, and failure modes are usually discovered one stack trace at a time. When error declarations live in the proto file, the failure surface becomes part of the API contract. One glance at the message definitions enumerates every way the domain can fail, before you ever write a handler.

That is what `protoc-gen-go-errors` does. You define your error messages in protobuf, run `buf generate`, and get ready-to-use `error` implementations with no runtime dependency.

## Two kinds of error messages

The plugin looks at every message whose Go name ends in `Error` and classifies it:

**Leaf errors** - a plain message with an `option (errors.display)` describing how to format it:

```proto
message PaymentDeclinedError {
  option (errors.display) = "payment declined: {transaction_id}";
  string transaction_id = 1;
}
```

**Sum errors** - a message containing exactly one `oneof`, each alternative being an error message. This is the "_domain error in one type_" pattern:

```proto
message CheckoutError {
  oneof kind {
    InsufficientStockError insufficient_stock = 1;
    PaymentDeclinedError payment_declined = 2;
    CouponInvalidError coupon_invalid = 3;
    OtherError other = 4;
  }
}
```

This is the "_domain error in one type_" pattern, and it is where protobuf gets closest to a Rust error enum. Instead of a dozen unrelated error types scattered through the codebase with no shared shape, the domain is summarized by a single `CheckoutError` whose every failure mode is visible in the message definition. `OtherError` is there to acknowledge that the list is not exhaustive - Rust does the same with a catch-all variant. Later, a type switch on `Kind` is the Go analogue of Rust's exhaustive `match`: every alternative is spelled out in the source, so the failure surface of a service is never a mystery.

Everything else - plain messages, normal protobuf fields - is left alone.

## Setting up

Install the plugin the usual way:

```sh
go install github.com/varunbpatil/protoc-gen-go-errors@latest
```

The rest of the toolchain is [mise](https://mise.jdx.dev) managed, exactly like the rest of my projects:

```toml
[tools]
"go" = "1.27.1"
"buf" = "1.72.0"
"protoc-gen-go" = "1.36.12"
```
{: file=".mise.toml"}

## Getting the option definition

The `(errors.display)` option is just a `google.protobuf.MessageOptions` extension. You could copy the file into your repo, but you would be maintaining a fork of an extension nobody should change. Instead, depend on the published module from the BSR:

```yaml
version: v2
modules:
  - path: proto
deps:
  - buf.build/varunbpatil-oss/protoc-gen-go-errors
```
{: file="buf.yaml"}

```sh
buf dep update
```

The import path is namespaced, so it cannot collide with anything you already have:

```proto
import "protoc-gen-go-errors/options.proto";
```

One subtlety: `options.proto` declares `option go_package = "github.com/varunbpatil/protoc-gen-go-errors/errors"`. Your generated Go code blank-imports that package to register the extension, so the Go module must also be on your module path:

```sh
go get github.com/varunbpatil/protoc-gen-go-errors
```

## Declaring the errors

A fuller example, in the style I actually use:

```proto
syntax = "proto3";

package checkout.v1;

import "protoc-gen-go-errors/options.proto";

option go_package = "example.com/shop/gen/checkoutv1";

message CheckoutError {
  oneof kind {
    InsufficientStockError insufficient_stock = 1;
    PaymentDeclinedError payment_declined = 2;
    CouponInvalidError coupon_invalid = 3;
    OtherError other = 4;
  }
}

message InsufficientStockError {
  option (errors.display) = "only {available} of {requested} in stock";
  int32 available = 1;
  int32 requested = 2;
}

message PaymentDeclinedError {
  option (errors.display) = "payment declined: {transaction_id}";
  string transaction_id = 1;
  GatewayError gateway = 2;
}

message GatewayError {
  option (errors.display) = "gateway returned {code}";
  string code = 1;
}

message CouponInvalidError {
  option (errors.display) = "coupon {coupon} is invalid";
  string coupon = 1;
}

message OtherError {
  option (errors.display) = "{message}";
  string message = 1;
}
```

A few behaviors worth knowing:

- `{field}` placeholders interpolate the corresponding field getter (`GetTransactionId()`, `GetAvailable()`, ...). Unknown placeholders are a code-generation error.
- Want a literal percent sign? Escape it (`50%% off`) - the display format is translated into a `fmt.Sprintf` format string under the hood.
- A field whose type is itself an error message (has its own `(errors.display)`) makes the generated error **unwrap** to it. Here `PaymentDeclinedError.Unwrap()` returns the `GatewayError`. Only one such field is allowed, which is reasonable - `Unwrap` is singular.
- The `oneof` alternatives must be error messages too. The plugin validates this and fails loudly otherwise, which beats discovering it via a broken `go build`.
- Message naming matters: only Go names ending in `Error` are touched. This is how you keep `NormalMessage`-style types out of the generated output.

## Generating

`buf.gen.yaml` is pretty much the standard protobuf setup plus one plugin:

```yaml
version: v2
plugins:
  - local: protoc-gen-go
    out: gen
    opt: paths=source_relative
  - local: protoc-gen-go-errors
    out: gen
    opt: paths=source_relative
inputs:
  - directory: proto
```
{: file="buf.gen.yaml"}

```sh
buf generate
```

Neither plugin needs to know about the other. `protoc-gen-go` produces the messages as usual; `protoc-gen-go-errors` adds a second generated file. For the sum error above, you get this:

```go
func (e *CheckoutError) Error() string {
	switch v := e.Kind.(type) {
	case *CheckoutError_InsufficientStock:
		return v.InsufficientStock.Error()
	case *CheckoutError_PaymentDeclined:
		return v.PaymentDeclined.Error()
	case *CheckoutError_CouponInvalid:
		return v.CouponInvalid.Error()
	case *CheckoutError_Other:
		return v.Other.Error()
	default:
		return "unknown error"
	}
}
```
{: file="gen/checkout/v1/checkout.errors.pb.go (excerpt)"}

Plus a uniform `From()` constructor that wraps any of the sum's own leaves:

```go
type fromCheckoutError interface {
	error
	proto.Message
	checkoutErrorMarker()
}

func (e *CheckoutError) From(leaf fromCheckoutError) *CheckoutError {
	switch v := leaf.(type) {
	case *InsufficientStockError:
		return &CheckoutError{Kind: &CheckoutError_InsufficientStock{
			InsufficientStock: v,
		}}
	case *PaymentDeclinedError:
		return &CheckoutError{Kind: &CheckoutError_PaymentDeclined{
			PaymentDeclined: v,
		}}
	case *CouponInvalidError:
		return &CheckoutError{Kind: &CheckoutError_CouponInvalid{
			CouponInvalid: v,
		}}
	case *OtherError:
		return &CheckoutError{Kind: &CheckoutError_Other{
			Other: v,
		}}
	default:
		panic(fmt.Sprintf("protoc-gen-go-errors: %T is not one of the error messages of CheckoutError", leaf))
	}
}
```

The argument is typed against an unexported interface that only `CheckoutError`'s
own leaves satisfy - each leaf implements a private `checkoutErrorMarker()` to
opt in. Hand it an `InsufficientStockError` and it compiles; hand it a leaf of
some other sum error and the compiler stops you instead of a runtime panic. The
per-alternative `FromPaymentDeclinedError(...)` constructors are still generated
if you prefer to spell out the variant.

And the leaves come out like this:

```go
func (e *PaymentDeclinedError) Error() string {
	return fmt.Sprintf("payment declined: %v", e.GetTransactionId())
}

func (e *PaymentDeclinedError) Unwrap() error {
	if v := e.GetGateway(); v != nil {
		return v
	}
	return nil
}

func (*PaymentDeclinedError) checkoutErrorMarker() {}
```

One detail I am fond of: the generated `Unwrap` never returns a typed nil. A hand-written `return e.GetGateway()` returns a non-nil `error` interface wrapping a nil pointer, and `errors.As` behaves like a toddler with a heartbeat monitor. The nil guard is the difference between "works" and "works until a nil cause shows up in production".

## Using them

Nothing about the generated code is magical - it is the standard `errors` package doing its thing:

```go
var checkoutErr *checkoutv1.CheckoutError

if errors.As(err, &checkoutErr) {
	switch checkoutErr.Kind.(type) {
	case *checkoutv1.CheckoutError_InsufficientStock:
		// show the shopper what is in stock
	case *checkoutv1.CheckoutError_PaymentDeclined:
		// ask for another payment method
	}
}
```

Because sum errors `Unwrap()` to their leaf, both `errors.As` and `errors.Is` work through the whole chain, including the nested `GatewayError`. The whole thing stays in the standard library - no error-sentinel package, no third-party unwrapping helper.

## A small bonus: the Result type

Once errors are first-class protobuf types, returning them from a Go method becomes ergonomic instead of awkward. The repo ships a tiny generic `Result` in the [`util`](https://github.com/varunbpatil/protoc-gen-go-errors/tree/main/util) package, modeled after [Rust's `Result<T, E>`](https://doc.rust-lang.org/std/result/):

```go
import (
	g "github.com/varunbpatil/protoc-gen-go-errors/util"
)

func (s *CheckoutService) Checkout(ctx context.Context, req *CheckoutRequest) g.Result[*CheckoutResponse, *checkoutv1.CheckoutError] {
	if err := s.validateCoupon(req.GetCoupon()); err != nil {
		return g.Err[*CheckoutResponse](new(checkoutv1.CheckoutError).From(err))
	}

	if err := s.gateway.Charge(ctx, req); err != nil {
		declined := new(checkoutv1.CheckoutError).From(
			&checkoutv1.PaymentDeclinedError{TransactionId: req.GetTxId(), Gateway: err},
		)
		return g.Err[*CheckoutResponse](declined)
	}

	return g.Ok[*CheckoutResponse, *checkoutv1.CheckoutError](&CheckoutResponse{OrderId: req.GetTxId()})
}
```

The response type and the error type are both explicit in the signature, and the caller can branch on the error with a type switch in one line:

```go
resp := s.Checkout(ctx, req)
if resp.IsErr() {
	switch resp.Err().Kind.(type) {
	case *checkoutv1.CheckoutError_InsufficientStock:
		return fail(http.StatusConflict, resp.Err())
	case *checkoutv1.CheckoutError_PaymentDeclined:
		return fail(http.StatusPaymentRequired, resp.Err())
	}
	return fail(http.StatusBadRequest, resp.Err())
}
return resp.MustGet(), nil
```

`Result` covers the usual surface - `IsOK()`, `IsErr()`, `Get()`, `MustGet()`, `OrElse(...)`, `OrEmpty()` - and `Err()` is typed, so the type switch above just works.

## Trade-offs

Nothing here is free, and I would not use this everywhere:

- **Your proto file is now the home of a cross-cutting concern.** That is fine when protobuf already owns your API, and it gives you `buf breaking` checks on error shapes for free. For a small internal service with three errors, the ceremony is not worth it.
- **The display strings are for developers and logs.** `{field}` interpolation produces a readable string, not a localized user message. If you need "only 3 of 5 in stock" in twelve languages, that is a separate concern.
- **The model is opinionated.** One oneof per sum error, "Error"-suffixed names, a single unwrappable field. The constraints are deliberate - they keep the generated code tiny and predictable - but a fully generic error system this is not.

What you get in exchange is the closest thing Go has to thiserror: declare the error, generate the boilerplate, spend the saved time on the parts of the codebase that actually need you.