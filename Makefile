.PHONY: wait/% start start/% stop stop/%

test: start rake/test stop

rake/test:
	bundle exec rake test

confluent/confluent.tgz:
	mkdir -p confluent && wget http://packages.confluent.io/archive/1.0/confluent-1.0-2.10.4.tar.gz -O confluent/confluent.tgz

confluent/EXTRACTED: confluent/confluent.tgz
	tar xzf confluent/confluent.tgz -C confluent --strip-components 1 && touch confluent/EXTRACTED

wait/zookeeper: start/zookeeper
	while ! nc localhost 2181 </dev/null; do echo "Waiting for zookeeper..."; sleep 1; done

wait/kafka: start/kafka
	while ! nc localhost 9092 </dev/null; do echo "Waiting for Kafka..."; sleep 1; done

wait/registry: start/registry
	while ! nc localhost 8081 </dev/null; do echo "Waiting for Registry..."; sleep 1; done

start: wait/registry

start/zookeeper: confluent/EXTRACTED
	confluent/bin/zookeeper-server-start -daemon confluent/etc/kafka/zookeeper.properties

start/kafka: wait/zookeeper confluent/EXTRACTED
	confluent/bin/kafka-server-start -daemon confluent/etc/kafka/server.properties

start/registry: wait/kafka confluent/EXTRACTED
	nohup confluent/bin/schema-registry-start confluent/etc/schema-registry/schema-registry.properties 2> log/schema-registry.err > log/schema-registry.out < /dev/null &

stop/zookeeper: confluent/EXTRACTED
	confluent/bin/zookeeper-server-stop

stop/kafka: confluent/EXTRACTED
	confluent/bin/kafka-server-stop

stop/registry: confluent/EXTRACTED
	confluent/bin/schema-registry-stop

stop: stop/registry stop/kafka stop/zookeeper
