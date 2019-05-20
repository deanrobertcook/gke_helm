# GKE cluster code
The application logic and config for my own GKE cluster. 

The purpose of this little project was to set up a cluster the "right" way, looking at things like security, container optimisation, monitoring, alerting, CI etc. from the ground up, using a simple application (code taken from [Todo MVC](http://todomvc.com/examples/typescript-react/#/), my [deployment is accessible here](http://35.244.170.92), if the IP hasn't changed). This turned out to be much trickier than anticipated and there were many things to be learnt, so I didn't get as far as I'd liked, but below are some of the things I managed to achieve over the weekend. 

The limited size of my GKE cluster using the free credits from Google also proved to be a hurdle when setting up the ELK stack, since it seems to be quite a CPU and memory hog... 

Things would like to dive into more, or that still are not working:
* Using Helm 3 (no need for a secure Tiller deployment!)
* Fix the application logs (after introducing the init system, it seems as though they're not being passed to stdout in the container)
* Spinning up a few more nodes to support ELK
* Introduce Prometheus and alerting (after installing a single-node ELK cluster, my other pods were getting evicted and I had no idea for a whole night!)
* Look into typescript and react, get back into some web development
* Look more into NodeJS

## Things I've learnt

### Securing Helm
After working from the advice of many different resources, I later [found one](https://engineering.bitnami.com/articles/helm-security.html}) that summarised the issues with Helm security perfectly. 

If I had to do this again, then I would probably look into Helm 3, as it does away with the Tiller installation and in doing so makes the next two security issues moot. 

#### RBAC, users and service accounts, and roles
By default, the tiller installation is installed in the kube-system namespace with default serviceaccount from that namespace. luckily, In GKE, this seems to be more restricted. In order for Tiller to work, and to limit the damage done should there be a security breach, I installed it into it's own namespace with a custom service account (as recommended). A cluster role was defined and assigned to the account with two role-bindings: one for each of the Tiller and the default namespaces, giving Tiller full read/write access to those namespaces.

**Note:** Using RBAC for tiller and providing it a serviceaccount has some inconvenient drawbacks. When trying to install the nginx-ingress controller, for example, it needed some clusterroles in order to watch for changes in nodes in the cluster. Since Tiller is the one executing the installation, and it didn't have cluster-wide admin rights, it couldn't assign these privileges. The shortest workaround for that was to install a new Tiller instance with cluster-wide rights, install the controller and then remove the new Tiller installation again. This was sub-optimal, since the ingress is then not part of the same app and rollbacks and upgrades with helm become impossible, but the only other solution would be to perhaps copy in the templates and modify them as needed (however, in the end, the default GKE ingress started working for me, so I didn't need my own anyway!).

#### TLS
The next recommendation is to secure the communications between Tiller and the Helm tool using TLS. By default, an unencrypted gRPC protocol is used and, since Tiller is reachable from anywhere within the cluster, any pod can connect to Tiller and request that it perform actions on its behalf, essentially upgrading its access rights to those of Tiller. In order to fix this, I had to learn how to create root authorities, private keys and certificates using openssl and install those in tiller and helm. The article linked above even had an elegant makefile to automate the process. 

### Git-crypt and GPG:
Since the root CA key generated in the TLS step needs to be kept safe so that any future clients wanting to connect to Tiller can get a client certificate, I decided to keep it in VCS using git-crypt. Git-crypt looks for files similar to the way .gitignore does, and then uses a local GPG entry to encrypt those files upon pushing and decrypts them again upon pull. Here I had to install GPG for the first time and I also finally answered for myself the question: how does one best keep sensitive material with a repo? 

### Docker best practices:
Having seen a few interesting blog articles on minimizing docker container sizes in the past, I decided to follow [this guide from Google](https://cloud.google.com/solutions/best-practices-for-building-containers) on the best practices in building containers. Here I've listed some new things for me:

#### Use an init system
Depending on how the Dockerfile is written, most containers either have the main executable running as the root process (PID 1) in the container's process namespace, or some script will take this role and the executable will be a child process. In either case, there can be issues. Generally, Linux process signals will be ignored or not passed down, and zombie processes generated by ill-behaved parents will not be cleaned up. To combat this, an init system (in particular I used [Tini](https://github.com/krallin/tini), as recommended) can be added as the `ENTRYPOINT` in the Dockerfile, and the main `CMD` will then be passed as an argument to the init system, making it a child process which receives signals properly. 

This actually had a noticeable affect when stopping the container. Without the init system, the SIGINT (or SIGTERM?) was being ignored by the python simple http server as process one. Killing the container would take 10 seconds as docker waited on the response from the process at PID 1 (which had obviously not registered any signal handlers). After installing tini, stopping the container would happen immediately. 
