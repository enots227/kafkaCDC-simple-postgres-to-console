FROM kafka

COPY ./confluentinc-kafka-connect-jdbc-10.0.1.zip /tmp/confluentinc-kafka-connect-jdbc-10.0.1.zip
COPY ./confluent-community-6.1.0.zip /tmp/confluent-community-6.1.0.zip
COPY ./connector-install.sh /tmp/connector-install.sh

COPY ./postgres-producer.properties /opt/kafka_2.13-2.7.0/config/postgres-producer.properties
COPY ./source-start.sh /source-start.sh
COPY ./postgres-source.json /connectors/postgres-source.json

COPY ./console-consumer.properties /connectors/console-consumer.properties
COPY ./sink-start.sh /sink-start.sh

RUN /tmp/connector-install.sh