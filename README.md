
## Installation

```st
[ EpMonitor current
	disableDuring: [ Metacello new
			repository: 'github://botwhytho/GtFontExplorer:main/src';
			baseline: 'GtFontExplorer';
			load ] ] asAsyncFuture
	await: AsyncFutureExecutionConfiguration default lowPriority
```
