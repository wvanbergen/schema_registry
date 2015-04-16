.PHONY: confluent/kafka/* confluent/zookeeper/* confluent/registry/* confluent/start confluent/stop

# Confluent platform tasks

confluent/start: confluent/rest/start

confluent/stop: confluent/rest/stop confluent/registry/stop confluent/kafka/stop confluent/zookeeper/stop

# Download & extract tasks

confluent/confluent.tgz:
	mkdir -p confluent && wget http://packages.confluent.io/archive/1.0/confluent-1.0-2.10.4.tar.gz -O confluent/confluent.tgz

confluent/EXTRACTED: confluent/confluent.tgz
	tar xzf confluent/confluent.tgz -C confluent --strip-components 1 && touch confluent/EXTRACTED

# Zookeeper tasks

confluent/zookeeper/start: confluent/EXTRACTED
	nohup confluent/bin/zookeeper-server-start confluent/etc/kafka/zookeeper.properties 2> log/zookeeper.err > log/zookeeper.out < /dev/null &
	while ! nc localhost 2181 </dev/null; do echo "Waiting for zookeeper..."; sleep 1; done

confluent/zookeeper/stop: confluent/EXTRACTED
	confluent/bin/zookeeper-server-stop

# Kafka tasks

confluent/kafka/start: confluent/zookeeper/start confluent/EXTRACTED
	nohup confluent/bin/kafka-server-start confluent/etc/kafka/server.properties 2> log/kafka.err > log/kafka.out < /dev/null &
	while ! nc localhost 9092 </dev/null; do echo "Waiting for Kafka..."; sleep 1; done

confluent/kafka/stop: confluent/EXTRACTED
	confluent/bin/kafka-server-stop

# schema-registry tasks

confluent/registry/start: confluent/kafka/start confluent/EXTRACTED
	nohup confluent/bin/schema-registry-start confluent/etc/schema-registry/schema-registry.properties 2> log/schema-registry.err > log/schema-registry.out < /dev/null &
	while ! nc localhost 8081 </dev/null; do echo "Waiting for schema registry..."; sleep 1; done

confluent/registry/stop: confluent/EXTRACTED
	confluent/bin/kafka-server-stop

# REST proxy tasks

confluent/rest/start: confluent/registry/start confluent/EXTRACTED
	nohup confluent/bin/kafka-rest-start confluent/etc/kafka-rest/kafka-rest.properties 2> log/kafka-rest.err > log/kafka-rest.out < /dev/null &
	while ! nc localhost 8082 </dev/null; do echo "Waiting for REST proxy..."; sleep 1; done

confluent/rest/stop: confluent/EXTRACTED
	confluent/bin/kafka-rest-stop
