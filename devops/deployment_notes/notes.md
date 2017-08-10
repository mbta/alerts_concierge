# Deploy Notes

## Building/Deploying

1. Will use Distillery to do the builds
2. AlertProcessor will be 1 release, ConciergeSite another
3. 1 Node for AlertProcessor. Will need to make sure jobs are running as a Singleton
on the cluster so we don't have multiple queues/workers per Alert
4. 2 Nodes for ConciergeSite
5. We will need to cluster the 2 ConciergeSite nodes with the AlertProcessor node.
Can set the vm.args on each node to accomplish this.
6. We can use edeliver to deploy each release, and configure the vm.args on each node so that the
releases will be in the same cluster.

## Managing

1. We're using logentries for logging already
2. What does MBTA use for AWS monitoring?
3. What does MBTA use for Application monitoring?

## Unanswered Questions

1. We need to render the header/footer from the main site. The best approach is likely
going to be to fetch the header/footer and have ConciergeSite render it.

2. Normally would use Edeliver to deploy the release, but given multiple release are likely
to be deployed simultaneously, is this still the best option? I know the MBTA deploys multiple
in-umbrella apps so worth checking what their practices are.

3. What size nodes/db do we want?
