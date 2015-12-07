### Sensu client image

This Docker image provides Sensu client containers. For documentation on the
project, refer to the [main documentation][main-readme].

#### Configuration

| Option                       | Note                                      |
|------------------------------|-------------------------------------------|
| `SENSU_CLIENT_NAME`          | Unique node name                          |
| `SENSU_CLIENT_ADDRESS`       | Node address                              |
| `SENSU_CLIENT_SUBSCRIPTIONS` | Comma-delimited list of subscrption roles |

please note that it may be more discreet to specify those options in
configuration file to be able to update them using container restart.

  [main-readme]: https://github.com/etki/docker-sensu/blob/master/README.md