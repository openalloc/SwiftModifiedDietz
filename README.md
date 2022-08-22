# SwiftModifiedDietz

A tool for calculating portfolio performance using the Modified Dietz method.

Available as an open source Swift library to be incorporated in other apps.

_SwiftModifiedDietz_ is part of the [OpenAlloc](https://github.com/openalloc) family of open source Swift software tools.

## ModifiedDietz

For details on the method, consult the [Modified Dietz method](https://en.wikipedia.org/wiki/Modified_Dietz_method) page on Wikipedia.

An example where the market value of a portfolio starts the month at `$105` and drops to `$100` by the end. Midway `$10` is withdrawn. The net performance is `+5.0%`.

```swift
typealias MD = ModifiedDietz<Double>
let df = ISO8601DateFormatter()
let beg = df.date(from: "2020-06-01T12:00:00Z")!
let mid = df.date(from: "2020-06-16T00:00:00Z")!
let end = df.date(from: "2020-06-30T12:00:00Z")!

let period = DateInterval(start: beg, end: end)
let mv = MD.MarketValueDelta(105, 100)
let cf: MD.CashflowMap = [mid: -10.0]
let md = MD(period, mv, cf)!

print("\(md.performance * 100)%")

=> 5.0%
```

Note that `performance` can return NaN if the sum of the starting market value and adjusted net cash flow is 0. Such a value is detectable with the `.isNaN` property on the return value.

## Types

The `MarketValueDelta` and `CashFlowMap` types are declared within `ModifiedDietz`, where `T` is your `BinaryFloatingPoint` data type:

`MarketValueDelta` specifies the beginning and ending market value for the period. Note that the `end` value can be less than the `start` value.

```swift
public struct MarketValueDelta {
    public let start, end: T
    public init(start: T, end: T) {
        self.start = start
        self.end = end
    }
}   
```

`CashFlowMap` specifies the inflow (positive) or outflow (negative) of cash on particular dates. (Dates outside of period are ignored.)

```swift
typealias CashflowMap = [Date: T]
```

It's often convenient to declare your own derivative type:

```swift
typealias MD = ModifiedDietz<Float>
```

## Initialization

Two initializers are provided, one more explicit than the other, but functionally equivalent:

- `init?(period: DateInterval, startValue: T, endValue: T, cashflowMap: [Date: T], epsilon: T)` - Conveniently initialize a ModifiedDietz with explicit parameters.

- `init?(DateInterval, ModifiedDietz<T>.MarketValueDelta, ModifiedDietz<T>.CashflowMap, epsilon: T)` - Initialize a ModifiedDietz with the specified parameters.

Initialization will fail and return `nil` if provided nonsense parameters, such as a period with zero duration.

The initialization values are also available as properties:

- `let period: DateInterval` - The period for which performance will be calculated. NOTE: `start < x <= end`; exclusive of start; inclusive of end.

- `let marketValue: ModifiedDietz<T>.MarketValueDelta` - The beginning and ending market value.

- `let rawCashflowMap: ModifiedDietz<T>.CashflowMap` - Optional map of cash flows for dates within the period

- `let epsilon: T` - Optional precision for comparing values that are very close to one another.

## Instance Properties and Methods

Computed properties are lazy, meaning that they are only calculated when first needed.

- `var adjustedNetCashflow: T` - Adjusted Net Cash Flow is the sum of each flow `Fi` multiplied by its weight `Wi`. Also known as total time-weighted cash flows (ttwcf)

- `var adjustedPeriod: DateInterval` - The net period excludes both (1) the time until the user funds, and (2) after the user defunds.

- `var averageCapital: T` - Average capital over the period.

- `var gainOrLoss: T` - Total gain (or loss) over period, independent of cash flow.

- `var netCashflowMap: ModifiedDietz<T>.CashflowMap` - Valid map of cash flows for period. Includes non-zero cashflows that are within `period.start < $0 <= period.end`

- `var netCashflowTotal: T` - Net external inflow (F) for the period. Also known as total net cash flows (tncf) Contributions to a portfolio are treated as positive flows while withdrawals are negative flows.

- `var orderedCashflowDates: [Date]` - Ordered list of valid cash flow dates.

- `var performance: T` - The calculated rate of return (R). Note: can return `NaN/Inf` if the sum of the starting market value and adjusted net cash flow is `0`.

## See Also

Swift open-source libraries (by the same author):

* [AllocData](https://github.com/openalloc/AllocData) - standardized data formats for investing-focused apps and tools
* [FINporter](https://github.com/openalloc/FINporter) - library and command-line tool to transform various specialized finance-related formats to the standardized schema of AllocData
* [SwiftCompactor](https://github.com/openalloc/SwiftCompactor) - formatters for the concise display of Numbers, Currency, and Time Intervals
* [SwiftNiceScale](https://github.com/openalloc/SwiftNiceScale) - generate 'nice' numbers for label ticks over a range, such as for y-axis on a chart
* [SwiftRegressor](https://github.com/openalloc/SwiftRegressor) - a linear regression tool that’s flexible and easy to use
* [SwiftSeriesResampler](https://github.com/openalloc/SwiftSeriesResampler) - transform a series of coordinate values into a new series with uniform intervals
* [SwiftSimpleTree](https://github.com/openalloc/SwiftSimpleTree) - a nested data structure that’s flexible and easy to use

And open source apps using this library (by the same author):

* [FlowAllocator](https://openalloc.github.io/FlowAllocator/index.html) - portfolio rebalancing tool for macOS
* [FlowWorth](https://openalloc.github.io/FlowWorth/index.html) - a new portfolio performance and valuation tracking tool for macOS


## License

Copyright 2021, 2022 OpenAlloc LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributing

Contributions are welcome. You are encouraged to submit pull requests to fix bugs, improve documentation, or offer new features. 

The pull request need not be a production-ready feature or fix. It can be a draft of proposed changes, or simply a test to show that expected behavior is buggy. Discussion on the pull request can proceed from there.

Contributions should ultimately have adequate test coverage. See tests for current entities to see what coverage is expected.
