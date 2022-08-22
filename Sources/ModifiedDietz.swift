//
//  ModifiedDietz.swift
//
// Copyright 2021, 2022 OpenAlloc LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation


public final class ModifiedDietz<T: BinaryFloatingPoint> {
    
    public struct MarketValueDelta {
        public let start, end: T
        public init(start: T, end: T) {
            self.start = start
            self.end = end
        }
    }

    public typealias CashflowMap = [Date: T]
    
    /// The period for which performance will be calculated.
    /// NOTE: start < x <= end; exclusive of start; inclusive of end
    public let period: DateInterval
    
    /// The beginning and ending market value.
    public let marketValue: MarketValueDelta
    
    /// Optional map of cash flows for dates within the period
    public let rawCashflowMap: CashflowMap
    
    /// Optional precision for comparing values that are very close to one another.
    public let epsilon: T
    
    /// Conveniently initialize a `ModifiedDietz` with explicit parameters.
    public convenience init?(period: DateInterval,
                             startValue: T,
                             endValue: T,
                             cashflowMap: CashflowMap = [:],
                             epsilon: T = 0.0001) {
        let mvd = MarketValueDelta(start: startValue, end: endValue)
        self.init(period, mvd, cashflowMap, epsilon: epsilon)
    }
    
    /// Initialize a `ModifiedDietz` with the specified parameters.
    public init?(_ period: DateInterval,
                 _ marketValue: MarketValueDelta,
                 _ rawCashflowMap: CashflowMap = [:],
                 epsilon: T = 0.0001) {
        guard period.start < period.end, (0.0...1.0).contains(epsilon) else { return nil }
        self.period = period
        self.marketValue = marketValue
        self.rawCashflowMap = rawCashflowMap
        self.epsilon = epsilon
    }
    
    /// Valid map of cash flows for period.
    /// Includes non-zero cashflows that are within `period.start < $0 <= period.end`
    public lazy var netCashflowMap: CashflowMap = {
        rawCashflowMap.filter {
            period.start < $0 &&
            $0 <= period.end &&
            epsilon < abs($1)
        }
    }()
    
    /// Ordered list of valid cash flow dates.
    public lazy var orderedCashflowDates: [Date] = {
        netCashflowMap.keys.sorted(by: { $0 < $1 })
    }()
    
    /// Net external inflow (F) for the period.
    /// Also known as total net cash flows (tncf)
    /// Contributions to a portfolio are treated as positive flows while withdrawals are negative flows.
    public lazy var netCashflowTotal: T = {
        netCashflowMap.reduce(0) { $0 + $1.value }
    }()
    
    /// The net period excludes both (1) the time until the user funds, and (2) after the user defunds.
    public lazy var adjustedPeriod: DateInterval = {
        var nuStart: Date = period.start
        var nuEnd: Date = period.end
        if marketValue.start == 0,
           let first = orderedCashflowDates.first {
            nuStart = first
        }
        if marketValue.end == 0,
           let last = orderedCashflowDates.last {
            nuEnd = last
        }
        return DateInterval(start: nuStart, end: nuEnd)
    }()
    
    /// Adjusted Net Cash Flow is the sum of each flow Fi multiplied by its weight Wi.
    /// Also known as total time-weighted cash flows (ttwcf)
    public lazy var adjustedNetCashflow: T = {
        netCashflowMap.reduce(0) { accum, flow in
            let factor = cashFlowAdjustmentFactor(flow.key)
            let adjustedCashflow = flow.value * factor
            return accum + adjustedCashflow
        }
    }()
    
    /// Total gain (or loss) over period, independent of cash flow.
    public lazy var gainOrLoss: T = {
        marketValue.end - marketValue.start - netCashflowTotal
    }()
    
    /// Average capital over the period.
    public lazy var averageCapital: T = {
        marketValue.start + adjustedNetCashflow
    }()
    
    /// The calculated rate of return (R).
    /// Note: can return NaN/Inf if the sum of the starting market value and adjusted net cash flow is 0.
    public lazy var performance: T = {
        gainOrLoss / averageCapital
    }()
}

// MARK: - Internal helpers

extension ModifiedDietz {
    internal func intervalOfTheFlow(_ transactedAt: Date) -> TimeInterval {
        transactedAt.timeIntervalSince(adjustedPeriod.start)
    }
    
    internal func cashFlowAdjustmentFactor(_ transactedAt: Date) -> T {
        T((adjustedPeriod.duration - intervalOfTheFlow(transactedAt)) / adjustedPeriod.duration)
    }
}

extension ModifiedDietz: Equatable {
    public static func == (lhs: ModifiedDietz<T>, rhs: ModifiedDietz<T>) -> Bool {
        lhs.period == rhs.period &&
        lhs.marketValue == rhs.marketValue &&
        lhs.rawCashflowMap == rhs.rawCashflowMap
    }
}

extension ModifiedDietz.MarketValueDelta: Hashable {}
extension ModifiedDietz: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(period)
        hasher.combine(marketValue)
        hasher.combine(rawCashflowMap)
    }
}
