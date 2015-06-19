
AWS_CONFIG=aws_config.json
PACKER=packer
PFLAGS=-var-file=$(AWS_CONFIG)

SOURCE = bamboo-docker-update.json
TARGETS = $(basename $(SOURCE))

all: $(TARGETS)

$(TARGETS): 
	$(PACKER) build $(PFLAGS) $@.json
