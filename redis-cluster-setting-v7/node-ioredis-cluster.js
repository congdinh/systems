/**** ENV
# Redis Cluster 1
REDIS_CLUSTER_DEFAULT_HOST_ONE=127.0.0.1
REDIS_CLUSTER_DEFAULT_PORT_ONE=7000,7001,7002,7003,7004,7005
# Redis Cluster 2
REDIS_CLUSTER_DEFAULT_HOST_TWO=
REDIS_CLUSTER_DEFAULT_PORT_TWO=
# Redis Cluster 3
REDIS_CLUSTER_DEFAULT_HOST_THREE=
REDIS_CLUSTER_DEFAULT_PORT_THREE=
****/

import Redis from "ioredis";

export const redisClusterNodes = () => {
  const {
    REDIS_CLUSTER_DEFAULT_HOST_ONE: redisClusterHostOne,
    REDIS_CLUSTER_DEFAULT_PORT_ONE: redisClusterPortOne,
    REDIS_CLUSTER_DEFAULT_HOST_TWO: redisClusterHostTwo,
    REDIS_CLUSTER_DEFAULT_PORT_TWO: redisClusterPortTwo,
    REDIS_CLUSTER_DEFAULT_HOST_THREE: redisClusterHostThree,
    REDIS_CLUSTER_DEFAULT_PORT_THREE: redisClusterPortThree,
  } = process.env;
  const redisClusterOne =
    redisClusterPortOne &&
    redisClusterPortOne.split(",").map((port) => {
      return {
        host: redisClusterHostOne,
        port: port,
      };
    });
  const redisClusterTwo =
    redisClusterPortTwo &&
    redisClusterPortTwo.split(",").map((port) => {
      return {
        host: redisClusterHostTwo,
        port: port,
      };
    });
  const redisClusterThree =
    redisClusterPortThree &&
    redisClusterPortThree.split(",").map((port) => {
      return {
        host: redisClusterHostThree,
        port: port,
      };
    });
  return [...redisClusterOne, ...redisClusterTwo, ...redisClusterThree];
};

const nodes = redisClusterNodes();
const redis = new Redis.Cluster(nodes, {
  scaleReads: "slave",
});

export default redis;
