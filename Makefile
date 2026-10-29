# Port 4000 belongs to the human developer (make start).
# Agents never use it; they run on 4441 to 4449 (see AGENTS.md).

.PHONY: prepare test check kill-port-4000 start

prepare:
	mix setup

test: prepare
	mix test

# What a pull request needs: warnings as errors, formatting, tests.
check: prepare
	mix precommit

kill-port-4000:
	@pids="$$(lsof -tiTCP:4000 -sTCP:LISTEN 2>/dev/null)"; \
	if [ -n "$$pids" ]; then \
		echo "Stopping processes on port 4000: $$pids"; \
		kill $$pids 2>/dev/null || true; \
		sleep 1; \
		pids="$$(lsof -tiTCP:4000 -sTCP:LISTEN 2>/dev/null)"; \
		if [ -n "$$pids" ]; then \
			echo "Force stopping processes on port 4000: $$pids"; \
			kill -9 $$pids 2>/dev/null || true; \
		fi; \
	fi

# Frees port 4000, prepares, starts the server and opens the browser once
# it answers. The key comes from the main checkout's .env (config/runtime.exs).
start:
	@$(MAKE) kill-port-4000
	@$(MAKE) prepare
	@echo "Server: http://localhost:4000"
	@( \
		tries=0; \
		while [ $$tries -lt 300 ]; do \
			if curl -fsS -o /dev/null --max-time 2 "http://localhost:4000/"; then \
				open "http://localhost:4000"; \
				exit 0; \
			fi; \
			tries=$$((tries + 1)); \
			sleep 0.4; \
		done; \
		echo "The server did not answer within two minutes; open http://localhost:4000 yourself." >&2 \
	) &
	mix phx.server
