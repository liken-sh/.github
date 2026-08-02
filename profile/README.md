# liken

**Li**nux + **K**ubernetes: a small operating system that boots a
machine directly into Kubernetes and uses Kubernetes as the service
manager.

The image is immutable, and it has no shell, no package manager, and
no libc. A `Cluster` resource declares the fleet: the releases, the
machines, and the workloads. Each machine downloads a release, checks
every byte against pinned digests, and writes it into the spare slot
of an A/B pair, so a bad release rolls back with a reboot.

Start here:

* [`liken`](https://github.com/liken-sh/liken) is the whole project in
  one repository: the code, the build, the plans, and the design
  documents. It is written to be read.
* [The manual](https://liken.sh/docs/) tells an operator how to
  install liken and run a cluster.
* [The release channel](https://releases.liken.sh) publishes every
  release, its notices, and its sources.
