plot:
	cat $(request) | vegeta attack -duration=$(duration)s -rate=$(rate) > results.bin
	vegeta report -type=json results.bin > metrics.json
	cat results.bin | vegeta plot > latency.html
	open latency.html
