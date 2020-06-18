plot:
	cat $(request) | vegeta attack -duration=$(duration)s -rate=$(rate) > results.bin
	vegeta report -type=json results.bin > metrics.json
	cat results.bin | vegeta plot -title=$(request)-for-$(duration)s-at-$(rate)rps > latency.html
	open latency.html

show-last:
	vegeta report results.bin

show-last-json:
	cat metrics.json | jq
