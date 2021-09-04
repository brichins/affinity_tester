# Affinity Tester

Uninterrupted usage of protocols with sessions on top of UDP, such as for example
[STUN](https://en.wikipedia.org/wiki/STUN)
and
[DTLS](https://en.wikipedia.org/wiki/Datagram_Transport_Layer_Security),
require session affinity.
For Kubernetes this means that as long as the backend pool of pods is unchanged (no scaling, no deleting of pods)
that for 2 packets P and Q sent successively from the same client source address and with a small enough time interval between P and Q then

 - Packets P and Q packets are served by the same pod
 - Packets P and Q are presented to the pod with the same reflective address

where address is the combination of IP and port. 
(Note that due to NAT'ing on the internet the client source address may be different from the reflective address).

Some versions and configurations of Kubernetes incorrectly do not satisfy these requirements.
That is a pity because violation results in sessions to be disrupted and parts of media streams to be lost.
This is a tool to validate if your version and configuration of Kubernetes satisfies the above requirements.

# Usage

Prerequisite are to have git, make, docker and kubectl installed locally, and have
your kubectl configured such that it runs commands against the Kubernetes
cluster that you want to test. Then check out this git repository locally.

**Step 1** is to deploy the server part of the affinity-tester in your Kubernetes cluster. 
This creates 3 pods with a pre-build Docker container from Dockerhub that runs the code in `server/`.
```
make apply-deployment
``` 

**Step 2** is to create a service in your cluster that is reachable from the outside.
```
make apply-service
```

Important! Before moving on to step 3 wait for the EXTERNAL-IP of the
affinity-tester service to go from pending to a real IP address.  Then update
`TARGET_ADDR` in `env.list` with the EXTERNAL-IP of the affinity-tester
service.

**Step 3** is to start the client. The client won't stop until you kill it with CTRL-C.
You may want to run this in a separate terminal and keep an eye on the logs.
The client logs at a regular interval statistics on packets sent and lost (in white text).
Upon detecting either a change in pod or a change in reflective address the client logs this change (in red text).
Examples of client logs are given in the section at the bottom of this document.

```
make client
```

Before proceeding with the next step let the client run for a while and ensure operation is normal (no packet loss or errors).

**Step 4** is to try out operations that you suspect cause your version and
configuration of Kubernetes to violate the requirements while keeping out an
eye on the logs.

You can for example try to scale the number of nodes in the cluster.
If you have permission to do so you can apply the change directly to the cluster or via the Azure Portal.
Alternatively, when a node-autoscaler is in place then you can use the following command to create a dummy
deployment that requests a large amount CPUs and thus is likely to trigger node scaleup.
```
make node-scaleup
```

**Final step**: when done kill the client with CTRL-C then delete the deployments and services used for this test
from your Kubernetes cluster with

```
make clean
```


# Client log examples


Normal operation
```
13:35:20.176 [info]  CLIENT-1058228236 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"
 
13:35:20.178 [info]  CLIENT-1951551396 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"
 
13:35:20.179 [info]  CLIENT-1231230857 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-wp62r"

13:35:20.179 [info]  CLIENT-1119310468 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-wp62r"

13:35:20.179 [info]  CLIENT-1660267191 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"

13:35:20.179 [info]  CLIENT-1867595734 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-wmd4l"

13:35:20.179 [info]  CLIENT-1416569880 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"

13:35:20.179 [info]  CLIENT-1494119945 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"

13:35:20.179 [info]  CLIENT-1287257719 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"

13:35:20.179 [info]  CLIENT-1754411049 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-vvwtx"

13:35:20.179 [info]  CLIENT-2027630483 sent 73 messages of which 0 message(s) lost, served by pod "affinity-tester-f7b7c454b-wmd4l"
````

Reflective addresses changing and connections reshuffled to different pods.
```
13:39:40.298 [error] x_address changed 281180084103413 -> 281180129454325
 
13:39:40.301 [error] x_address changed 168938675670756 -> 168939181412068
 
13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-vvwtx" -> "affinity-tester-f7b7c454b-wmd4l"

13:39:40.301 [error] x_address changed 198986074465210 -> 198986461389754

13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-vvwtx" -> "affinity-tester-f7b7c454b-wp62r"

13:39:40.301 [error] x_address changed 178522546746642 -> 178523472835858
 
13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-vvwtx" -> "affinity-tester-f7b7c454b-wp62r"
 
13:39:40.301 [error] x_address changed 103827146416722 -> 163584140608386

13:39:40.301 [error] x_address changed 193485410580671 -> 193485011859647

13:39:40.301 [error] x_address changed 143070733047111 -> 143071591699783

13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-wmd4l" -> "affinity-tester-f7b7c454b-wp62r"

13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-wmd4l"

13:39:40.301 [error] x_address changed 202804918136626 -> 202805355523890

13:39:40.301 [error] x_address changed 184967784611710 -> 184969201172350

13:39:40.301 [error] x_address changed 151506937880200 -> 151506046459528
 
13:39:40.301 [error] pod_name changed "affinity-tester-f7b7c454b-vvwtx" -> "affinity-tester-f7b7c454b-wmd4l"

13:39:40.301 [error] x_address changed 154008506374998 -> 154008402828118
```

Packet loss and reshuffled connections
```
14:05:48.472 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"
 
14:05:48.494 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"
 
14:05:48.494 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.494 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.494 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.494 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"
 
14:05:48.495 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.495 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.495 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"

14:05:48.495 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"
 
14:05:48.495 [error] pod_name changed "affinity-tester-f7b7c454b-wp62r" -> "affinity-tester-f7b7c454b-vvwtx"
```
