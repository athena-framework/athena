.PHONY: docs
docs: ## Generates Athena documentation
	crystal docs \
		lib/athena-spec/src/athena-spec.cr \
		lib/athena-event_dispatcher/src/athena-event_dispatcher.cr \
		lib/athena-config/src/athena-config.cr \
		lib/athena-dependency_injection/src/athena-dependency_injection.cr \
		lib/athena-serializer/src/athena-serializer.cr \
		lib/athena-validator/src/athena-validator.cr \
		lib/athena-validator/src/spec.cr \
		src/athena.cr \
		src/spec.cr

.PHONY: spec
spec: ## Runs the Athena spec suite against Crystal latest
	crystal spec --order random --error-on-warnings --exclude-warnings ./spec

.PHONY: nightly_spec
nightly_spec: ## Runs the Athena spec suite against Crystal nightly
	docker run --rm -v $(PWD):/athena -w /athena crystallang/crystal:nightly-alpine make spec
