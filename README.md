# kafkaCDC-simple-postgres-to-console
This project is mainly created for practice purposes and a way for me to get understanding of Kafka and the applications involved in a change data capture (CDC) architecture. Also gave me more of a love hate appreciation for Docker and Docker networks. By documenting my experience I could possibly help anyone else trying to learn Kafka... and this is ultimately something I could put on my resume.

In these instructions, you will notice I am very redundant (just like your production servers should be 😉). It is because when I read through tutorials I skim read and usually end up missing steps, so I repeat so you could catch important points if you are like me.

<span style="color:grey;font-size:6px;">I know my jokes are not that funny, but they make me laugh at myself. It makes me have fun writing this too... I am not a writer at heart... so why I am I doing this... idk.</span>

#
## Software Required
- Docker - https://www.docker.com/products/docker-desktop
- Download packages used by the Docker images.
    - ZooKeeper (3.6.2)
        - Home Page: https://zookeeper.apache.org/
        - Download Page: https://zookeeper.apache.org/releases.html 
        - Donwload Link: https://www.apache.org/dyn/closer.lua/zookeeper/zookeeper-3.6.2/apache-zookeeper-3.6.2-bin.tar.gz 
        - Download Location: `%KAFKA_CDC_REPOSITORY%/zookeeper/apache-zookeeper-3.6.2-bin.tar.gz`
        > Note: Download the binary version and not the source code. If you are downloading a new version, then change the version number in the `zookeeper/Dockerfile`, `zookeeper/zookeeper-install.sh`, and `zookeeper/zookeeper-start.sh`.
    - Kafka (2.13-2.7.0)
        - Home Page: https://kafka.apache.org/
        - Download Page: https://kafka.apache.org/downloads
        - Download Link: https://www.apache.org/dyn/closer.cgi?path=/kafka/2.7.0/kafka_2.13-2.7.0.tgz
        - Download Location: `%KAFKA_CDC_REPOSITORY%/kafka/kafka_2.13-2.7.0.tgz`
        > (!) <span style="color:red">Download the binary version and not the source code (Kafka shows the source code src download first. DO NOT DOWNLOAD THAT VERSION).</span>
        
        > Note: Versioning of Kafka follows \<scala version>-\<kafka version>. The version presented it scala version 2.13 and kafka version 2.7.0.
        
        > Note: If you are downloading a new version, then change the version number in the `kafka/Dockerfile`, `kafka/kafka-install.sh`, `kafka/kafka-start.sh`, `connector/sink-start.sh`, `connector/source-start.sh`, and `connector/connector-install.sh`.
    - Confluent Community (6.1.0)
        - Product Page: https://www.confluent.io/product/confluent-platform
        - Download Page: https://docs.confluent.io/platform/current/installation/installing_cp/zip-tar.html
        - Download Link (ZIP): http://packages.confluent.io/archive/6.1/confluent-community-6.1.0.zip
        - Download Link (TAR): http://packages.confluent.io/archive/6.1/confluent-community-6.1.0.tar.gz
            - The ZIP version is used; however, the TAR version would easily be usable with small tweeks.
        - Download Location: `%KAFKA_CDC_REPOSITORY%/connector/confluent-community-6.1.0.zip`
        > Note: . If you are downloading a new version, then change the version number in the `connector/Dockerfile` and `connector/connector-install.sh`.
    - Confluent Kafka Connect - JDBC Connect (Source and Sink) (10.0.1)
        - Download Page: https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc
        - Download Location: `%KAFKA_CDC_REPOSITORY%/connector/confluentinc-kafka-connect-jdbc-10.0.1.zip`
        > Note: . If you are downloading a new version, then change the version number in the `connector/Dockerfile` and `connector/connector-install.sh`.

#
## Create Docker Environment
### Create Base Image

All the Docker images that we will be creating all need to use the Java Runtime Environment (JRE). Since you might be messing around with these images a lot it isn't fun to have to reinstall JRE everytime (or the java development kit JDK if you are using that... which this repo is). This first image will be the base for all other images, so we could skip that step of the build.

> Alternatively, you could probably find a Java Docker image in the Docker Hub if you do not want to create your own.

Steps in `java/Dockerfile` and `java/java-install.sh`:
1. Set Timezone
    - Set timezone of image environment. The JRE install will require timezone set, otherwise, it will prompt user intervention.
    - If you do not know your timezone value, then type `timeselect` in the Linux bash. It will ask you a series of questions and display the correct information to you.
    - This step has already been scripted. Set your environment timezone by modifying the `java/Dockerfile`.
        -  `ENV TZ="<your timezone>"`
        > Note: This is already set to `America/Los_Angeles` within this repo. If you live somewhere else, then you might need to do the above steps. 
1. Set Java Environment Variables
    - The JAVA_HOME environment variable should be the path to the JRE or JDK install.
    - The CLASSPATH environment variable should be the path to the JRE or JDK lib folder.
1. Start the Install Script.
    - Sets the timezone from the environment variable.
    - Pull the latest package list from Linux's package manager.
    - Perform `openjdk-11-jdk` install.
    > Note: The JDK might not be needed depending on your development environment. If everything is compiled, then JRE will suffice.

> (!) <span style="color:red">This is the only image that is not included in the docker-compose.yml. Build this image for the other images by running</span>
>
> Navigate to java directory on your local computer: `cd %KAFKA_CDC_REPOSITORY%/java`
> 
> Build custom java image: `docker build -t java .`

#

### Create ZooKeeper Image
From the information that I have gathered, the ZooKeeper application acts as a conductor coordinating the Kafka nodes and maintains the configuration of the cluster.

Steps in `zookeeper/zookeeper-install.sh`:
1. Builds from the Java image.
1. Extracts the ZooKeeper application
    - The compressed ZooKeeper binary is copied over from the Dockerfile into the /tmp directory.
    - The compressed folder is than extracted into the /opt/apache-zookeeper-3.6.2 directory.
1. Create the ZooKeeper data directory.
    - Creates /var/zookeeper/data

Interesting note: Kafka is trying to sever ties from ZooKeeper and become independent, so ZooKeeper might not be needed when you are reading this. Eventually, the Kafka nodes themselves will elect a leader between them ending their relationship with ZooKeeper.

#

### Create Kafka Image (Broker Image)
Kafka itself (ignoring connectors) is a distributed database (also referred to as a distributed log) and is not a messaging queue like I initially thought it was due to misinformation. When viewing it as a queue I was confused why we needed a source connector and sink connector because I thought all you needed was to pipeline data to it and it would handle getting data to its destinations; however, when viewing it as a database it is not actually doing anything. The data sits there like any other database, you have to design applications (connectors) to funnel data in and out of it. Once I viewed it that way it started to make a lot more sense to me.

Steps in `kafka/kafka-install.sh`:
1. Builds from the Java image.
1. Extracts the Kafka application
    - The compressed Kafka binary is copied over from the Dockerfile into the /tmp directory.
    - The compressed folder is than extracted into the /opt/kafka-2.13-2.7.0 directory.

#

### Create Connector Image (Source and Sink Image)
Many people are using Kafka in similar ways to pipeline data in from one source and out to another destination. To make thinks simpler they designed a framework to help standardize these tasks. These applications merely pipeline data from a destination to the Kafka cluster (referred to as source connectors) or they merely pipeline data from the Kafka cluster to some destination (referred to as sink connectors).

There several open source connectors available, so you do not have to create your own. The one I will use is the confluent jdbc connector to pipeline data from postgres to Kafka.

Steps in `connector/connector-install.sh`:
1. Builds from the Kafka image.
    - For Kafka connectors to run you need the Kafka application installed, so we will be building this image off of the previous one.
1. Install unzip
    - This will allow us to extract the confluent folders.
1. Install curl
    - We will use curl to register the source connector topic.
1. Extracts the Confluent Community
    - The Confluent JDBC requires this program for it to work, so we will install it to the /opt folder.
1. Extracts the Confluent JDBC
    - This is the Confluent JDBC source and sink connector that we will use for syncing the Kafka cluster with changes to the postgres database. Postgres will be the source.
1. Optional: Log only WARN to reduce the logs and initial confusion on what is going on. The WARN logs and up are the only ones you need to concern yourself with that I have noticed for development.
    > Note: Currently this is already done. See connector/connector-install.sh and modify the last step if you want to re-enable INFO logging or even enable DEBUG logging.

### Create Postgres
Postgres is the SQL database used. We merely use the postgres Docker image provided in Docker Hub. Additionally, we link the volumne `/var/lib/postgresql/data` on the VM to a `./postgres-data` folder to ensure the data persists between Docker restarts.

#
## Configure Source and Sink Connectors
> Note: I will be interchanging between source connector and producer along with sink connector and consumer in the following section. A source connector is a producer application and a sink connector is the consumer application. 

> Note: A Kafka node is also referred to as a broker.

### Postgres Source Connector Properties
This file will contain information on what information will be pulled from postgres, the Kafka initial nodes for connecting to the cluster, and several other factors.

See `connector/postgres-producer.properties` for the following section.

We need to configure the initial Kafka nodes for the producer to connect the Kafka cluster. In the docker-compose.yml I labeled two Kafka nodes broker1 and broker2. For a production environments you would want to use host name and not IP addresses so you are not bounded to use a particular IP. Additionally, you would want to specify at least 2 initial brokers in the event that one node goes down the producer could fallback to the other. I would even argue 3 or more servers is ideal.
> `bootstrap.servers=broker1:9092,broker2:9092`

The next property to configure is the group id. This must be unique to only the source connectors.
> `group.id=producer-cluster`

The next properties indicate how the data will be stored in the Kafka cluster. Kafka is a simple key-value pair database system and does not have the concept of tables and rows. (!) <span style="color:red">These settings have nothing to do with the database. Initially I tried placing `io.confluent.connect.jdbc.JdbcSourceConnector`. Do not do that.</span>
> `key.converter=org.apache.kafka.connect.json.JsonConverter`
> `value.converter=org.apache.kafka.connect.json.JsonConverter`

The other 10 properties I do not have much understanding of yet.

The final property for plugin path indicates where you install your connectors programs. I installed everything to the `/opt` directory, so I just provided that folder. I have also seen `/usr/share/java/lib`.

### Console Consumer Connector Properties
The console consumer is a simple way to display the results to the console for testing.

The only property that I was concerned with was group id again. This must be unique to only the sink connectors. (!) <span style="color:red">Initially I tried making this the same as the producer id because it wasn't receiving any logs in the console, but this was due to another issue.</span>
> `group.id=consumer-cluster`

There is also security settings that I could configure, but since I am practicing I ignored using these.

### Postgres Source Topic
This JSON will register the a topic to the Kafka cluster through communicating with ZooKeeper. The topic will have configuration data for connectors.

Notable fields:
- `name` - the name of the topic.
- `connector.class` - the source connector Java library used.
- `connection.url` - the postgres connection string.
- `connection.user` - the postgres database username.
- `connection.password` - the postgres database password.
- `table.whitelist` - the tables to sync with the Kafka cluster.
- `mode` - the mode of how it will sync. There are different modes if you lookup the confluent JDBC connector. The incrementing mode indicates that it will add to the Kafka cluster, but not modify existing records or delete records. Ex. you have an record and the database and update a value in that row or even delete the record the Kafka cluster will not register those events for this mode.
- `incrementing.column.name` - column that is used to indicate whether it has processed that row.
```json
{ 
    "name":"jdbc_source_pg_increment",
    "config": {
        "connector.class":"io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url":"jdbc:postgresql://postgres:5432/db_user",
        "connection.user":"db_user",
        "connection.password":"db_password",
        "table.whitelist":"public.accounts",
        "mode":"incrementing",
        "incrementing.column.name":"id",
        "topic.prefix":"jdbc_source_pg_increment.",
        "tasks.max":"1",
        "poll.interval.ms":"5000",   
        "timestamp.delay.interval.ms":"1000",
        "batch.max.rows":"1",
        "validate.non.null":false
    }
 }
```

#
## Combining it All Together
At this point I have given all the information for setting up the Docker images and property fields. So I will go over how it starts up.

1. Start Postgres
1. Start ZooKeeper
1. Start Broker 1 and Broker 2 (Kafka instances)
    - The following are set through the `kafka/kafka-start.sh` script modifying the `%KAFKA_INSTALL%/config/server.properties` file in their respective VMs.
    - `ZOOKEEPER_CONNECT` - nodes will target the ZooKeeper for coordination.
    - `BROKER_ID` - each node needs a unique ID.
    - `ADVERTISED_LISTENERS` - should be set to the host name rather than localhost to prevent conflicts. If either are localhost (0.0.0.0), then they will not be able to communicate to each other. Reference them by host name.
1. Start Source Connector
    - Command for start distributed cluster: `%KAFAKA_INSTALL%/bin/connect-distributed.sh %KAFAKA_INSTALL%/config/postgres-producer.properties`
    - You could also use `bin/connect-standalone.sh` for development if you were not using more than one broker. We have Docker to create multiple brokers to simulate a production environment more closely, so I would work with distributed myself.
1. Create the Topic
    - Kafka and the source connector are not doing anything yet since their is no topic to write to.
    - You could use Postman to hit one of the two brokers with the endpoint `POST /connectors`. Send that Postgres Source Topic json as the payload.
    - For convenience, I added this step in the sink connector since that is the next image that starts.
        > (!) <span style="color:red">I believed that the sink connector starts quicker before the source connector fully initializes, so when the sink connector starts you might have to restart the sink connector for it to start working or make the Postman request like previously stated.</span>
1. Start Sink Connector
    - As previously stated this start script for the sink connector sends a POST request to the Kafka cluster to register the postgres topic.
    - It then proceeds to start the console consumer through `%KAFKA_INSTALL%/bin/kafka-console-consumer.sh --bootstrap-server broker1:9092 --topic jdbc_source_pg_increment.accounts --consumer.config /connectors/console-consumer.properties --from-beginning`

#
## Problems Encountered :(
### Kafka Source Code Downloaded
 - I accidentally downloaded the source code first, this is what happened...
    - It to gave me this error `Classpath is empty. Please build the project first e.g. by running ./gradlew jar PscalaVersion=2.11.12`.
    - Tried running `./gradlew jar PscalaVersion=2.11.12` with in the extracted Kafka directory and it gave me an error that resulted in me install JDK needing to be installed rather than merely install the JRE.
    - I proceeded to install JDK with took a lot longer than just JDK.
    - Successfully built the Kafka project.
    - Encountered another issue and when I was researching it I found this StackOverflow post https://stackoverflow.com/questions/50197965/classpath-is-empty-please-build-the-project-first-e-g-by-running-gradlew-ja.
    - Immediately realized my mistake and lost several hours of my life. Yay programming and not reading instructions.

#
## Resources
Tutorial Articles that helpped me:
- JDBC source connector with PostgreSQL - https://help.aiven.io/en/articles/3416789-jdbc-source-connector-with-postgresql
- Kafka Connect JDBC Source Connector - https://turkogluc.com/kafka-connect-jdbc-source-connector/

Articles that went over the architecture, terms, and better understanding of Kafka in general:
- Intro to Apache Kafka: How Kafka Works https://www.confluent.io/blog/apache-kafka-intro-how-kafka-works/
    - Best one for terms and architecture by far.
- JDBC Connector Source Connector Configuration Properties - https://docs.confluent.io/kafka-connect-jdbc/current/source-connector/source_config_options.html#jdbc-source-configs
- JDBC Sink Connector Configuration Properties - https://docs.confluent.io/kafka-connect-jdbc/current/sink-connector/sink_config_options.html
- JDBC Source Connector for Confluent Platform - https://docs.confluent.io/kafka-connect-jdbc/current/source-connector/index.html
- JDBC Sink Connector for Confluent Platform - https://docs.confluent.io/kafka-connect-jdbc/current/sink-connector/index.html