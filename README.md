# GKE cluster code
The application logic and config for my own GKE cluster. It currently uses Helm 2 with a secured installation of Tiller to install charts and package the application logic.

## Things I've learnt

### Securing Helm
After working from the advice of many different resources, I later [found one](https://engineering.bitnami.com/articles/helm-security.html}) that summarised the issues with Helm security perfectly. 

#### RBAC, users and service accounts, and roles
By default, the tiller installation is installed in the kube-system namespace with default serviceaccount from that namespace. luckily, In GKE, this seems to be more restricted. In order for Tiller to work, and to limit the damage done should there be a security breach, I installed it into it's own namespace with a custom service account (as recommended). A cluster role was defined and assigned to the account with two role-bindings: one for each of the Tiller and the default namespaces, giving Tiller full read/write access to those namespaces.

#### TLS
The next recommendation is to secure the communications between Tiller and the Helm tool using TLS. By default, an unencrypted gRPC protocol is used and, since Tiller is reachable from anywhere within the cluster, any pod can connect to Tiller and request that it perform actions on its behalf, essentially upgrading its access rights to those of Tiller. In order to fix this, I had to learn how to create root authorities, private keys and certificates using openssl and install those in tiller and helm. The article linked above even had an elegant makefile to automate the process. 

### Git-crypt and GPG:
Since the root CA key generated in the TLS step needs to be kept safe so that any future clients wanting to connect to Tiller can get a client certificate, I decided to keep it in VCS using git-crypt. Git-crypt looks for files similar to the way .gitignore does, and then uses a local GPG entry to encrypt those files upon pushing and decrypts them again upon pull. Here I had to install GPG for the first time and I also finally answered for myself the question: how does one best keep sensitive material with a repo? 

