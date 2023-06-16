![status](https://img.shields.io/badge/status-up-green) ![uptime](https://img.shields.io/badge/uptime-100%25-green) ![maintainer](https://img.shields.io/badge/maintainer-dhsoni-blue)

# Production Ready Highly Available Splunk Infrastructure Setup Using Terraform, Chef & Jenkins! 

**Splunk Indexer Clustering Environment!**

An indexer cluster is a group of Splunk nodes that, working in concert, provide a redundant indexing and searching capability. There are three types of nodes in a cluster.

**Manager Node:** A single manager node to manage the cluster.

**Indexers:** Several peer nodes that handle the indexing function for the cluster, indexing and maintaining multiple copies of the data and running searches across the data. Indexer clusters feature automatic failover from one peer node to the next. This means that, if one or more peers fail, incoming data continues to get indexed and indexed data continues to be searchable.

**Search Heads:** One or more search heads to coordinate searches across all the peer nodes.

**Forwarders:** Splunk instance that forwards data to another Splunk instance, such as an indexer or another forwarder, or to a third-party system.

![splunk](https://github.com/DhruvinSoni30/Splunk_Infrastructure_Chef/blob/main/images/splunk.png)
