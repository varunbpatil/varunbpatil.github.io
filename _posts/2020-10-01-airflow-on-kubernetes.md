---
layout: post
title: "An outing with Airflow on Kubernetes"
---

I build ML pipelines for processing vast amounts of data and serving hundreds of data science models with very strict QoS parameters. This blog post is not an Airflow tutorial but rather talks about my journey with building and running highly scalable and reliable ML pipelines on Kubernetes with Airflow and requires some understanding of Airflow and Kubernetes.

<br/>
#### What would we do without you, Kubernetes?

Airflow has a mature [Celery executor](https://airflow.apache.org/docs/stable/executor/celery.html) that allows us to run tasks concurrently across multiple worker nodes. This works quite well. Then why do we need something more Kubernetes native?

**Infrastructure**

- The Celery executor requires a message broker like RabbitMQ or Redis.
- We probably also need [Flower](https://flower.readthedocs.io/en/latest/) for monitoring the Celery workers.

Two things we could do without.

**Packaging code**

Unless we are using [DockerOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/docker_operator/index.html) or [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html) (which we will discuss shortly), our DAGs and all its dependencies must be present on all the Celery worker nodes. We will either have to use a shared volume or synchronize code across multiple nodes ourselves. For example, if a [PythonOperator](https://airflow.apache.org/docs/stable/howto/operator/python.html) task depends on TensorFlow, we need to have TensorFlow installed on every worker node. Sure, we could automate all of this, but it is still a pain when we have to deal with thousands of Airflow tasks with different, often conflicting dependencies.

**Dependency hell**

What happens when we need to run legacy code which depends on TensorFlow 1.x alongside modern code which depends on TensorFlow 2.x? One way is to have Airflow create a virtual environment and run code inside it using something like the [PythonVirtualenvOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/python_operator/index.html#airflow.operators.python_operator.PythonVirtualenvOperator). But, there are severe limitations to the [PythonVirtualenvOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/python_operator/index.html#airflow.operators.python_operator.PythonVirtualenvOperator) in that we can only run simple functions (not object-oriented code) and the start-up times for those tasks are atrocious when we have to create virtual environments with huge Python packages like TensorFlow and PyTorch every time the task is executed. Another way is to containerize our Airflow tasks (code + dependencies) and use the [DockerOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/docker_operator/index.html) or [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html).

**Targeting tasks to particular nodes in the Celery cluster**

What happens when some tasks require a GPU to do their work? By default, all tasks are pushed to a default queue and all Celery workers are configured to listen to the default queue and so the task could get scheduled on any node. We'll have to create a different queue for these GPU tasks, pass the newly created queue as a parameter to whatever Airflow operator we are using and then configure the GPU nodes (which are also Celery workers) to wait for tasks on this new queue. Wouldn't it be nice if we didn't have to deal with all of these queues ourselves and simply label a node as `GPU` and have Airflow schedule GPU tasks on that node?

**Always on**

For bursty or batch workloads, it is important to be able to quickly add additional worker nodes to the cluster to handle the increased workload. It is also equally important to be able to easily scale down the number of nodes in the cluster when done to reduce wasted resources and operating costs (think of all the idling GPU nodes). Adding additional Celery worker nodes is straightforward, but, the workers have to be configured, packages and dependencies have to be installed, virtual environments have to be created, code has to be synced, etc before Airflow tasks can run on the new node all of which is cumbersome, to say the least, unless we are using the [DockerOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/docker_operator/index.html) or [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html). The result is "always on" Celery workers.

A common pattern starts to emerge from previous problems. Containerization (docker images) used along with [DockerOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/docker_operator/index.html) or [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html) seems to solve a lot of the major issues, but we are restricted to using only these two operators. We can't, for example, use the [PythonOperator](https://airflow.apache.org/docs/stable/howto/operator/python.html) or [BashOperator](https://airflow.apache.org/docs/stable/howto/operator/bash.html). Although we could do everything we ever want to do with just these two operators, we lose the expressiveness we would otherwise have had in our Airflow DAGs if we could use the entire gamut of Airflow operators.

What we need, therefore, is a way to combine the expressiveness of individual Airflow operators with the ability to run those tasks in an isolated, containerized environment. This is exactly what we can achieve by running Airflow on Kubernetes with the [Kubernetes executor](https://airflow.apache.org/docs/stable/executor/kubernetes.html). Read on to find out more.

<br/>
#### How to run Airflow on Kubernetes

There is a [stable helm chart](https://github.com/helm/charts/tree/master/stable/airflow) as well as a [helm chart from Astronomer.io](https://github.com/astronomer/airflow-chart) to quickly get started with Airflow on Kubernetes. Since this is not an Airflow on Kubernetes tutorial, I will not be discussing these helm charts, however, we will see more of its components in the sections below.

What is interesting though, is that there is more than one way to run Airflow tasks on Kubernetes.

- We could use the [Celery executor](https://airflow.apache.org/docs/stable/executor/celery.html) along with the [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html). This means we need to have a Celery cluster and a message broker (RabbitMQ, Redis, etc) in addition to our Kubernetes cluster. In the end, it is Kubernetes which is doing all the heavy lifting of executing the tasks; Celery is only there for coordination. This seems like a lot of additional Celery infrastructure we could do without. There is another major drawback to the [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html) though. All tasks will have to be written using the [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html). We cannot use any other operator like the [BashOperator](https://airflow.apache.org/docs/stable/howto/operator/bash.html) or [PythonOperator](https://airflow.apache.org/docs/stable/howto/operator/python.html). This imposes a huge restriction in transitioning existing DAGs from running on Celery workers to running on Kubernetes.
- We could just use the [Kubernetes executor](https://airflow.apache.org/docs/stable/executor/kubernetes.html) and have the entire Airflow infrastructure and tasks run as pods within the Kubernetes cluster. Wouldn't it be awesome if we could write Airflow DAGs using the full gamut of operators - [PythonOperator](https://airflow.apache.org/docs/stable/howto/operator/python.html), [BashOperator](https://airflow.apache.org/docs/stable/howto/operator/bash.html), etc - and still have these tasks run as independent pods inside the Kubernetes cluster? This is exactly what the [Kubernetes executor](https://airflow.apache.org/docs/stable/executor/kubernetes.html) provides. No more Celery to Kubernetes transition issues.

<br/>
#### How do we package DAGs and code for Airflow

All of our Airflow DAGs, the code they execute, and their dependencies are packaged as Docker images built and pushed to a private Docker registry which Kubernetes can then pull from. How we build and push docker images is not nearly as interesting as how we structure our Dockerfile(s). We maintain a Debian based Python3 base image with a bare-minimum of packages installed (Airflow included) and then use a [multi-stage docker build](https://docs.docker.com/develop/develop-images/multistage-build/) with [BuildKit improvements](https://docs.docker.com/develop/develop-images/build_enhancements/) to build Docker images for multiple environments (Dev, Test, Staging, Production) all from a single Dockerfile thereby reducing duplication.

Now, let's circle back and see how this solves the problem of **"Dependency hell"** as described above. If we have two different Airflow tasks that require different versions of the same package (say TensorFlow 1.x and 2.x or CPU vs GPU), all we have to do is build different Docker images and tell the Airflow task to use a particular image via the `executor_config` parameter. We can also target a specific node in the Kubernetes cluster with this parameter without having to maintain multiple queues like with the Celery executor. 

This is an example of what it all looks like. Firstly, the trimmed version of Dockerfile for multi-stage Docker builds (showing only the relevant portions).

```docker
# This is our Debian based Python3 base image with bare-minimum packages (including Airflow).
FROM python:3.6.9-stretch AS base
RUN pip install apache-airflow[kubernetes,postgres,crypto,async,password]==1.10.4 ...

# This is our base image with Tensorflow 1.x dependency (for legacy CPU code).
FROM base AS tensorflow1_cpu
RUN pip install tensorflow==1.15 ...

# This is our base image with Tensorflow 2.x dependency (for newer CPU code).
FROM base AS tensorflow2_cpu
RUN pip install tensorflow==2.2.0 ...

# This is our base image with Tensorflow 2.x GPU dependency (for newer GPU code).
FROM base AS tensorflow2_gpu
RUN pip install tensorflow-gpu==2.2.0 ...

# This is the build stage for the production docker image for legacy CPU code (TensorFlow 1.x).
FROM tensorflow1_cpu AS prod_legacy_cpu
RUN pip install ...
COPY <src> <dest>

# This is the build stage for the production docker image for newer CPU code (TensorFlow 2.x).
FROM tensorflow2_cpu AS prod_cpu
RUN pip install ...
COPY <src> <dest>

# This is the build stage for the production docker image for newer GPU code (TensorFlow 2.x).
FROM tensorflow2_gpu AS prod_gpu
RUN pip install ...
COPY <src> <dest>
```

This is how we use BuildKit enhancements to build a particular target image.

```bash
# Building an Airflow image for legacy Airflow CPU tasks (which depend on Tensorflow 1.x).
$ DOCKER_BUILDKIT=1 docker build -t airflow_tensorflow_legacy_cpu --target prod_legacy_cpu .

# Building an Airflow image for newer Airflow CPU tasks (which depend on Tensorflow 2.x).
$ DOCKER_BUILDKIT=1 docker build -t airflow_tensorflow_cpu --target prod_cpu .

# Building an Airflow image for newer Airflow GPU tasks (which depend on Tensorflow 2.x).
$ DOCKER_BUILDKIT=1 docker build -t airflow_tensorflow_gpu --target prod_gpu .
```

This is how we tell Airflow tasks to use a particular docker image via the `executor_config` parameter.

```python
# Legacy task.
predict_legacy_tensorflow_cpu = PythonOperator(
    task_id='predict_legacy_tensorflow_cpu',
    provide_context=True,
    python_callable=tf_predict_legacy_cpu,
		executor_config={
			"KubernetesExecutor": {"image": "airflow_tensorflow_legacy_cpu"}
		}
    dag=dag,
)

# Newer task.
predict_tensorflow_cpu = PythonOperator(
    task_id='predict_tensorflow_cpu',
    provide_context=True,
    python_callable=tf_predict_cpu,
		executor_config={
			"KubernetesExecutor": {"image": "airflow_tensorflow_cpu"}
		}
    dag=dag,
)
```

And finally, this is how we tell Airflow that a particular task should be executed on a particular node (for example, a task which requires GPU should only be executed on a GPU node) using the `executor_config` parameter.

```python
# The first step is to label the GPU nodes in Kubernetes appropriately.
$ kubectl label nodes <node> capability=gpu

# In the Airflow task's executor_config, specify the appropriate node-selectors.
predict_tensorflow_gpu = PythonOperator(
    task_id='predict_tensorflow_gpu',
    provide_context=True,
    python_callable=tf_predict_gpu,
		executor_config={
			"KubernetesExecutor": {
				"image": "airflow_tensorflow_gpu",
				"node_selectors": {
					"capability": "gpu"
				}
			}
		}
    dag=dag,
)
```

The benefits of the [Kubernetes executor](https://airflow.apache.org/docs/stable/executor/kubernetes.html) are immediately apparent in comparison to the [Celery executor](https://airflow.apache.org/docs/stable/executor/celery.html).

- Isolating code and dependencies is super-easy with Docker images.
- We don't have to restrict ourselves to the [DockerOperator](https://airflow.apache.org/docs/stable/_api/airflow/operators/docker_operator/index.html) or [KubernetesPodOperator](https://airflow.apache.org/docs/stable/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html) to achieve the above isolation.
- No need for multiple queues when we want to tie a task to a particular node.
- No need for additional UI to monitor worker nodes. The Kubernetes dashboard and CLI (kubectl) works well.

<br/>
#### Optimal resource usage

By containerizing our DAGs, code, and dependencies as Docker images we no longer have to prepare the worker nodes before they can be used (apart from installing a few Kubernetes and Docker dependencies and mounting shared volumes). With just a few `kubectl` commands, we can join a new node to the Kubernetes cluster or delete a node from the cluster. The best thing is there are zero changes required from Airflow or code or configurations to start using the new node (well, almost. Jump to the end of this article to find out more). Having such an insanely simple and quick way of adding or removing additional compute capacity from the cluster coupled with Airflow's ability to retry failed tasks gives us the ability to be extremely aggressive in commissioning and decommissioning worker nodes like using spot instances on AWS or Azure to massively reduce operation costs. So, the Kubernetes worker nodes need not be "always on".

<br/>
#### Performance

Documentation around the Kubernetes executor is scant and documentation around tweaking Airflow configuration for better performance on Kubernetes even more so. Airflow is designed for batch processing and not for real-time or near-real-time processing. Running Airflow on Kubernetes doesn't change that fact. This means Airflow works well when each task takes several minutes if not hours to complete. The same cannot be said when we have many tasks that only take a few seconds to complete.

This is what we can expect to see in the Airflow gantt chart with default Airflow and Kubernetes configurations and tasks taking only a few seconds to complete.

![AirflowGantt]({{ "/assets/airflow_gantt.png" | absolute_url }})

<center>Fig 1. Airflow delay between tasks with default configuration of Airflow and Kubernetes.</center>

<br/>
We expect that the next task will be scheduled immediately after the previous task completes. Unfortunately, we see a delay of over a minute between the first and the second task in the above image. The problem is exacerbated when we have hundreds of DAGs with many such low duration tasks.

Let us also understand what is happening inside the Kubernetes cluster. The Kubernetes executor creates one pod for each Airflow task. When the tasks are of such low duration, there is a large amount of "**pod churn**" happening within the Kubernetes cluster with hundreds of pods being created and deleted every second. This puts a lot of strain on some key Kubernetes components - [Scheduler](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/) (different from the Airflow scheduler), [Controller Manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/), and [Kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/). The end result is that there is a huge delay between the pods being scheduled on a node (`PodScheduled` state) and the containers becoming ready (`ContainersReady` state) even when the Docker image is already present on the node and is not being pulled again.

To reduce the delay between tasks (we cannot eliminate it), we made the following Airflow and Kubernetes configuration changes. Note that the values in the tables below are not recommendations. The aim is only to make the reader aware of the various knobs they can turn and what behavior to expect when they are turned.

**Airflow configuration**

|Section     |Configuration                  |Default|New|Comment                                                                                                                                                                                                                                                                                                                                                                                             |
|------------|-------------------------------|-------|---|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|[scheduler] |scheduler_heartbeat_sec        |5      |1  |This defines how often the Airflow scheduler should run and therefore how often new tasks are triggered. New tasks are triggered at most every (this many) seconds.                                                                                                                                                                                                                                 |
|[scheduler] |min_file_process_interval      |0      |5  |default = 0 results in a very tight loop where the Airflow scheduler spends most of the time parsing DAGs instead of scheduling tasks (CPU usage is also high). Higher value reduces scheduler CPU usage, but it also increases the delay between tasks by the same amount because the Airflow scheduler can schedule the DAGs in a DAG definition file no more than once every (this many) seconds.|
|[scheduler] |max_threads                    |2      |12 |Defines how many threads the scheduler can run. Recommended value is ncpus - 1.                                                                                                                                                                                                                                                                                                                     |
|[kubernetes]|worker_pods_creation_batch_size|1      |32 |The maximum number of Kubernetes pods that can be created in one scheduler loop. The default value of 1 combined with a default value of 5 for scheduler_heartbeat_sec means at most 1 new task can be created in Kubernetes every 5 seconds.                                                                                                                                                       |

<br/><br/>
**Kubernetes configuration**

The following changes to the Kubernetes configuration aim at improving the Pod throughput in a high pod churn scenario.

These QPS parameters are described beautifully in this [Applatix blog post](https://applatix.com/making-kubernetes-production-ready-part-2/).

|Component   |Configuration                  |Default|New|
|------------|-------------------------------|-------|---|
|kube-controller-manager|kube-api-qps, kube-api-burst   |20, 30 |300, 350|
|kube-scheduler|kube-api-qps, kube-api-burst   |50, 100|300, 350|
|kubelet     |kubeAPIQPS, kubeAPIBurst       |5, 10  |300, 350|

<br/>
With these changes to Airflow and Kubernetes configuration, we see delay between tasks drastically reduced from a minute or more to only a few seconds.

<br/>
#### Persistent database connections

Airflow has a metadata database to store information about DAGs, DAG runs, users, roles, connections, variables, etc. Airflow also maintains a SQLAlchemy connection pool to this metadata database which can be configured in airflow.cfg.

```yaml
[core]
# If SqlAlchemy should pool database connections.
sql_alchemy_pool_enabled = True

# The SqlAlchemy pool size is the maximum number of database connections
# in the pool. 0 indicates no limit.
sql_alchemy_pool_size = 5
```

During DAG parsing, Airflow creates a new connection to the metadata DB for each DAG. Every Airflow task also creates a connection to the metadata database separate from the SQLAlchemy connection pool since each task is running as an independent pod and is thus a different process. Also, Airflow isn't very good at closing unused connections. The result is a lot of open database connections. If we use Postgres as our metadata database, we can only have a maximum of 100 open connections by default. We can, of course, increase the connection limit in Postgres, but that will result in increased CPU and RAM usage. When we have a lot of DAGs and tasks running concurrently, the following error is all too common.

```bash
psycopg2.OperationalError: FATAL: sorry, too many clients already
```

The solution is to offload the work of database connection pooling to a proxy service like [PgBouncer](https://www.pgbouncer.org/) or [Pgpool](https://www.pgpool.net/mediawiki/index.php/Main_Page) which sits between Airflow and the metadata DB. This allows for precise control over the number of open database connections. PgBouncer, with its built-in retry logic, can further ensure connection resiliency.

The [Astronomer.io helm chart](https://github.com/astronomer/airflow-chart/blob/master/templates/pgbouncer/pgbouncer-deployment.yaml) provides a Kubernetes deployment spec for PgBouncer.

<br/>
#### Zombie apocalypse

Before [DAG serialization](https://airflow.apache.org/docs/stable/dag-serialization.html), DAGs were parsed by both the Airflow scheduler and webserver. To make DAG parsing fast and stable, it is imperative that we keep non-airflow imports to a minimum in the DAG definition file and move all business logic inside Airflow tasks. The DAG definition file should only describe the DAG and do nothing else.

This is, however, easier said than done. Maybe the function that a task needs to execute is defined in a different (maybe third-party) package and so that package needs to be imported. Maybe describing the DAG itself requires reading a configuration file and performing some computation on it. It is easy to see how additional logic and imports start creeping into the DAG definition file. It is all well and good if this code is vetted.

Consider what would happen if we were to import a third-party package into the DAG definition file and this third-party package created multiple sub-processes and then exits without waiting on their completion. Because the parent did not wait for the completion of those sub-processes, they end up as **zombie (or defunct)** processes. This is not a problem if Airflow was running directly on a Linux VM. The `init` process (PID 1) would adopt those zombie processes and `reap` them. But, with Airflow on Kubernetes, the Airflow scheduler and webserver are running as containers inside a Kubernetes pod and there is no `init` process inside the docker container to reap the zombies. PID 1 inside the docker container is usually Airflow (scheduler or webserver) itself which doesn't do any zombie reaping. Airflow DAGs are parsed every few seconds and every time it is parsed, new zombie processes get created that hog the process table. Eventually, the node will run out of PIDs to assign to new processes. A true zombie apocalypse. The whole PID 1 and zombie reaping problem is explained beautifully in this [article](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/).

The above example was not made up. We had the same issue when importing a particular version of the [joblib](https://github.com/joblib/joblib) python package in our DAG (the issue has since been fixed in the joblib package). Fortunately, the solution is extremely simple. Instead of having Airflow (scheduler or webserver) as PID 1 inside our docker containers, we need to have a process that can reap zombies just like the `init` process. `[tini](https://github.com/krallin/tini)` (init written backward) does exactly that. Simply adding tini as the ENTRYPOINT in Docker is enough to send those pesky zombies back to their graves.

<br/>
#### The curious case of Airflow on a multi-node Kubernetes cluster

In a previous section, I described how easy it is to scale a Kubernetes cluster by adding new nodes in response to bursty traffic and how Airflow will automatically start scheduling tasks on the new node *almost* without any changes. It's time to address the "almost" portion of it.

The Kubernetes scheduler works in mysterious ways... Well, not really. The Kubernetes scheduler uses a set of [policies](https://kubernetes.io/docs/reference/scheduling/policies/) to score nodes and then schedules pods on the node with the best score. Of particular interest is the `ImageLocalityPriority` policy which says a node that already has the docker image for a pod cached will be favored. This means Airflow tasks (ignoring all the other Kubernetes scheduler policies) will likely continue to be scheduled on existing nodes (where the Docker image has already been cached) rather than on the newly added node especially when the Docker image is not exactly *superleggera.*

There are multiple ways to solve this problem. The first way to solve it is by adding a soft pod anti-affinity on all Airflow task pods so that Kubernetes will try to schedule the Airflow tasks on nodes that are not already running some other Airflow task as much as possible. To do this, make the following modification to the kubernetes section inside `airflow.cfg`.

```
[kubernetes]

# The following has to be on a single line.
affinity = {"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight": 100,"podAffinityTerm":{"labelSelector":{"matchExpression":[{"key":"airflow-worker","operator":"Exists"}]},"topologyKey":"kubernetes.io/hostname"}}]}}
```

For details on what these terms mean in Kubernetes, check out this [link](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#an-example-of-a-pod-that-uses-pod-affinity).

Another way to solve this problem is by creating a Kubernetes DaemonSet to pre-pull the Docker image(s) to all the nodes in the cluster.

```yaml
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: airflow-image-pull
  namespace: mynamespace
spec:
  selector:
    matchLabels:
      name: airflow-image-pull
  template:
    metadata:
      labels:
        name: airflow-image-pull
    spec:
      serviceAccountName: airflow
      initContainers:
      - name: pre-pull-airflow-tensorflow-legacy-cpu
        image: airflow_tensorflow_legacy_cpu
        imagePullPolicy: IfNotPresent
        command: ["bash"]
      - name: pre-pull-airflow-tensorflow-cpu
        image: airflow_tensorflow_cpu
        imagePullPolicy: IfNotPresent
        command: ["bash"]
      - name: pre-pull-airflow-tensorflow-gpu
        image: airflow_tensorflow_gpu
        imagePullPolicy: IfNotPresent
        command: ["bash"]
      containers:
      - name: pause
        image: k8s.gcr.io/pause
```

The init container(s) pull the Docker image(s) that our Airflow tasks require. Once the images are pulled, the init containers go away and we are left with an extremely light-weight pause container that doesn't do anything. This DaemonSet is part of the helm chart we use. So, we actually don't have to make any changes when a new node is added to the cluster.

<br/>
Thats it folks. I hope this article serves as a good reference for potential problems and solutions for anyone looking to run Airflow on Kubernetes in production.
