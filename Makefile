.PHONY: docs
docs: ## Generates Athena documentation
	crystal docs lib/athena-event_dispatcher/src/athena-event_dispatcher.cr lib/athena-config/src/athena-config.cr lib/athena-dependency_injection/src/athena-dependency_injection.cr lib/athena-serializer/src/athena-serializer.cr src/athena.cr

.PHONY: spec
spec: ## Runs the Athena spec suite
	crystal spec --order random --error-on-warnings
