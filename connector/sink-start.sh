#!/bin/bash
export SCALA_VERSION="2.13"
export KAFKA_VERSION="2.7.0"
export KAFKA_HOME=/opt/kafka_$SCALA_VERSION-$KAFKA_VERSION

# Run this in Docker shell
cd /connectors
curl -s -H "Content-Type: application/json" -X POST -d @postgres-source.json $KAFKA_CONNECT/connectors/

# Start Kafka Connector
cd $KAFKA_HOME
exec bin/kafka-console-consumer.sh --bootstrap-server $KAFKA_BROKERS --topic jdbc_source_pg_increment.accounts --consumer.config /connectors/console-consumer.properties --from-beginning