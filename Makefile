# LCP RiskGuard — Makefile
#
# Convenience targets for the Pharos grading workflow. The full
# install story lives in install.sh; this file exposes the
# canonical commands as make targets.

.PHONY: all test test-foundry test-shell self-test benchmark compare clean install help

help:
	@echo "LCP RiskGuard — make targets"
	@echo ""
	@echo "  make install         one-shot install (Foundry + jq + forge-std + LCP Skill)"
	@echo "  make test            run all test gates (forge + shell + self-test)"
	@echo "  make test-foundry    forge test -vvv (runner output shape)"
	@echo "  make self-test       bash scripts/self-test.sh (offline runner checks)"
	@echo "  make compare TARGETS  multi-target comparison via scripts/compare.sh"
	@echo "  make benchmark       latency benchmark via scripts/benchmark.sh"
	@echo "  make fixtures        regenerate test/fixtures/*.json"
	@echo "  make clean           remove build artifacts"

install:
	@chmod +x install.sh
	@./install.sh

# All-test gate: forge + self-test (offline).
test: test-foundry self-test
	@echo ""
	@echo "[make] ALL TESTS PASSED"

test-foundry:
	@echo "[make] forge test -vvv"
	@forge test -vvv

self-test:
	@echo "[make] bash scripts/self-test.sh"
	@bash scripts/self-test.sh

# Multi-target comparison. Example:
#   make compare TARGETS="native:PROS 0xABC... 0xDEF..."
compare:
	@bash scripts/compare.sh $(TARGETS)

benchmark:
	@bash scripts/benchmark.sh

fixtures:
	@bash test/capture-output.sh

clean:
	@rm -rf out/ cache/ broadcast/
	@rm -f test/fixtures/sample-output.json test/fixtures/sample-filtered.json
	@rm -f ~/.lcp-riskguard-*.log
	@echo "[make] cleaned"