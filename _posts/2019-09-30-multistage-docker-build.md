---
layout: post
title: "Multistage docker build"
---

In the [previous post]({% post_url 2019-09-29-nuitka-code-obfuscation %}) we saw how to obfuscate Python code using [Nuitka](https://nuitka.net/pages/overview.html).

In this post, we'll look at how you can build a Docker image containing either plain Python code or obfuscated Python code out of a single `Dockerfile`.

This utilizes something called [Docker multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/).

Using Docker multi-stage builds, you can avoid having to maintain multiple `Dockerfile`s. For example, in this case, you needn't maintain one `Dockerfile` to build a Docker image with plain Python code and another to build a Docker image with obfuscated Python code.

A similar multi-stage `Dockerfile` can be used to generate slightly different images for [multiple environments like dev, qa, staging, production, etc](https://github.com/docker/cli/issues/1134#issuecomment-406449342).


```
# Set --build-arg SRC_FORMAT=clear|obfuscated during docker build.
ARG SRC_FORMAT=obfuscated

FROM python:3.6.8-stretch AS base
WORKDIR /usr/src/app

FROM base AS clear-code
COPY . .

FROM base AS obfuscated-code
COPY . .
RUN pip install cython && pip install nuitka==0.6.3
RUN ["./code_obfuscation.py"]
RUN ["rm", "code_obfuscation.py"]

# Cannot reference build arg in COPY --from. Hence creating an intermediate image.
FROM ${SRC_FORMAT}-code AS copy-src

FROM base AS final
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY --from=copy-src /usr/src/app/ .
ENTRYPOINT ["./entrypoint.sh"]
```

<br/>

Let us walk through the `Dockerfile` since there seems to be a lot happening here.

<br/>

The first line is a build argument to `docker build` to control whether the final Docker image should have plain Python code or obfuscated Python code.

* To build a Docker image with plain Python code

        $ docker build --build-arg SRC_FORMAT=clear ...

* To build a Docker image with obfuscated Python code

        $ docker build --build-arg SRC_FORMAT=obfuscated ...

<br/>

Then next step is to create a `base` image with no Python code files whatsoever.

```
FROM python:3.6.8-stretch AS base
WORKDIR /usr/src/app
```
This will form the base for all the subsequent build stages.

<br/>

Next, we have two build stages - one for the plain Python code and one for the obfuscated Python code.

The build stage for the plain Python code (`clear-code`) does nothing other than copy the Python files from the build context directly into the Docker image.
```
FROM base AS clear-code
COPY . .
```

The build stage for the obfuscated Python code (`obfuscated-code`) runs the code obfuscation script we saw in the [previous post]({% post_url 2019-09-29-nuitka-code-obfuscation %})
```
FROM base AS obfuscated-code
COPY . .
RUN pip install cython && pip install nuitka==0.6.3
RUN ["./code_obfuscation.py"]
RUN ["rm", "code_obfuscation.py"]
```

One <b>very important</b> thing to notice here is that, since the code obfuscation was done in separate `RUN` statements, the <b>intermediate layers will still contain plain Python code</b>. However, that is not a problem, since `obfuscated-code` is not the final image we are going to ship to the customer.

<br/>

Now that we have two intermediate docker images - `clear-code` and `obfuscated-code` - containing plain Python code and obfuscated Python code respectively, we can not build the final stage - `final`.

```
FROM base AS final
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY --from=copy-src /usr/src/app/ .
ENTRYPOINT ["./entrypoint.sh"]
```

This final stage will simply copy files from the previous build stage depending on whether we want plain Python code in our final image in which case we copy files from `clear-code` or whether we want obfuscated Python code in which case we copy files from `obfuscated-code`.

However, there is one small problem. The `COPY --from=` statement does not accept build arguments. So, we have to create another intermediate image before building the `final` image.

```
# Cannot reference build arg in COPY --from. Hence creating an intermediate image.
FROM ${SRC_FORMAT}-code AS copy-src
```

<br/>

Once all the build stages are complete, you will have a `final` image which contains either plain Python code or obfuscated Python code depending on the `--build-arg` you specified during `docker build`.
