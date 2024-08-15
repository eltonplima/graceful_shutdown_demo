# Calc

- [This example was created based on this presentation](https://www.youtube.com/watch?v=cbCgB9F6RrM)
- [Elixir and k8s](https://dashbit.co/blog/kubernetes-and-the-erlang-vm-orchestration-on-the-large-and-the-small)
- [Clustering Elixir](https://fly.io/docs/elixir/the-basics/clustering/)
- [Clustering fly.io](https://fly.io/docs/elixir/advanced-guides/clustering-from-home-to-your-app-in-fly/)

## Requests example

```bash
http POST http://localhost:4000/math/sum/1 <<<'{ "numbers": [1,2,3]}'
```

## Create cluster steps

```bash
./create-cluster.sh
kubectl apply -f k8s/01-postgres.yml
kubectl apply -f k8s/01-influxdb.yml
kubectl apply -f k8s/deployment.yml
docker build -t localhost:5001/elixir-graceful-shutdown:latest . && docker push localhost:5001/elixir-graceful-shutdown
# create a port forward to create the database and execute
# createdb graceful-shutdown-demo -U postgres
```

## Configure LoadBalancer
```bash
go install sigs.k8s.io/cloud-provider-kind@latest
cloud-provider-kind
# to discover the LB IP use
LB_IP=$(kubectl get svc/graceful-shutdown-demo -o=jsonpath='{.status.loadBalancer.ingress[0].ip}') 
# to test the service
curl "${LB_IP}":8000/health 
```

## Debugging DNS issues

https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/

## Build docker image
```bash
docker build -t localhost:5001/calc:latest . && docker push localhost:5001/calc:latest
```

## Issues

If you start to receive this message: cannot assign requested address

You can use the following config: echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse 

- https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files


To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
