//
//  MDTests.swift
//
// Copyright 2021 FlowAllocator LLC
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

@testable import ModifiedDietz
import XCTest

final class MDTests: XCTestCase {
    let df = ISO8601DateFormatter()

    typealias MD = ModifiedDietz<Double>
    
    func testBadInitPeriod() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let period = DateInterval(start: beg, end: beg)
        let mv = MD.MarketValueDelta(start: 100, end: 100)
        XCTAssertNil(MD(period, mv))
    }
    
    func testBadInitEpsilon() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 100, end: 100)
        XCTAssertNil(MD(period, mv, epsilon: 1.01))
    }
    
    func testNoChange() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 100, end: 100)
        let md = MD(period, mv)!
        XCTAssertEqual(0, md.performance, accuracy: 0.001)
    }

    func testDoubleNoTransaction() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 100, end: 200)
        let md = MD(period, mv)!
        XCTAssertEqual(1.0, md.performance, accuracy: 0.001)
    }

    func testNoChangeWithFlowAtExactStart() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-01T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let t1: MD.CashflowMap = [transactedAt1: 100] // adding 100 at start (which is ignored)
        let mv = MD.MarketValueDelta(start: 100, end: 200)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(1.0, md.performance, accuracy: 0.001)
    }

    func testNoChangeWithFlowOneSecAfterStart() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-01T12:00:01Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let t1: MD.CashflowMap = [transactedAt1: 100] // adding 100 at start
        let mv = MD.MarketValueDelta(start: 100, end: 200)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(0.0, md.performance, accuracy: 0.001)
    }

    func testNoChangeWithFlowAtMidway() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-15T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let t1: MD.CashflowMap = [transactedAt1: 100] // adding 100 at halfway point
        let mv = MD.MarketValueDelta(start: 100, end: 200)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(0.0, md.performance, accuracy: 0.001)
    }
    
    func testNoChangeWithFlowAtEnd() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-30T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let t1: MD.CashflowMap = [transactedAt1: 100] // adding 100 at end
        let mv = MD.MarketValueDelta(start: 100, end: 200)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(0.0, md.performance, accuracy: 0.001)
    }

    func testPositiveReturnOneFlowAtMidway() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-16T00:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 105, end: 100)
        let t1: MD.CashflowMap = [transactedAt1: -10]
        let md = MD(period, mv, t1)!
        XCTAssertEqual(-10, md.netCashflowTotal)
        XCTAssertEqual(-5, md.adjustedNetCashflow, accuracy: 0.01) // at halfway point
        XCTAssertEqual(0.05, md.performance, accuracy: 0.001)
    }
    
    func testNegativeReturnOneFlowAtMidway() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-16T00:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 105, end: 90)
        let t1: MD.CashflowMap = [transactedAt1: -10]
        let md = MD(period, mv, t1)!
        XCTAssertEqual(-10, md.netCashflowTotal)
        XCTAssertEqual(-5, md.adjustedNetCashflow, accuracy: 0.01) // at halfway point
        XCTAssertEqual(-0.05, md.performance, accuracy: 0.001)
    }

    func testTwoTxns() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-07T12:00:00Z")!
        let transactedAt2 = df.date(from: "2020-06-13T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let period = DateInterval(start: beg, end: end)
        let p1: Double = 100 * 215 // 21500
        let p2: Double = 90 * 190 // 17100
        let mv = MD.MarketValueDelta(start: p1, end: p2)
        let t1: MD.CashflowMap = [transactedAt1: -1095, transactedAt2: +350]
        let md = MD(period, mv, t1)!
        XCTAssertEqual(-1095 + 350, md.netCashflowTotal)
        XCTAssertEqual(-663.28, md.adjustedNetCashflow, accuracy: 0.01)
        XCTAssertEqual(-0.175, md.performance, accuracy: 0.001)
    }
    
    func testIgnoreTransactionNotInPeriod() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-30T12:00:01Z")! // not okay
        let t1: MD.CashflowMap = [transactedAt1: 1]
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 100, end: 100)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(0, md.performance, accuracy: 0.001)
    }
    
    func testIgnoreTransactionWithZeroAmount() throws {
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let transactedAt1 = df.date(from: "2020-06-30T12:00:0Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!
        let t1: MD.CashflowMap = [transactedAt1: 0]
        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 100, end: 100)
        let md = MD(period, mv, t1)!
        XCTAssertEqual(0, md.performance, accuracy: 0.001)
        XCTAssertEqual(0, md.netCashflowMap.count)
    }
    
    func testLiquidateAllNearStart() throws {
        let begPeriod = df.date(from: "2020-10-01T19:00:00Z")!  // period start
        let transactedAt = df.date(from: "2020-10-01T21:00:00Z")!  // two hours after start
        let endPeriod = df.date(from: "2020-11-01T19:00:00Z")!  // period end

        let period = DateInterval(start: begPeriod, end: endPeriod)
        let mv = MD.MarketValueDelta(start: 30000, end: 0)
        let rawCashflows: MD.CashflowMap = [
            transactedAt: 0,    // sell security for cash
            endPeriod: -33000,  //always flow out at end of period
        ]
        
        let md = MD(period, mv, rawCashflows)!
        XCTAssertEqual(3000, md.gainOrLoss)
        XCTAssertEqual(30000, md.averageCapital)
        XCTAssertEqual(0.1, md.performance, accuracy: 0.001)
        XCTAssertEqual(1, md.netCashflowMap.count)
    }

    func testLiquidateAllHalfway() throws {
        let begPeriod = df.date(from: "2020-09-01T19:00:00Z")!  // period start
        let transactedAt = df.date(from: "2020-09-15T19:00:00Z")!  // halfway point
        let endPeriod = df.date(from: "2020-10-01T19:00:00Z")!  // period end

        let period = DateInterval(start: begPeriod, end: endPeriod)
        let mv = MD.MarketValueDelta(start: 30000, end: 0)
        let rawCashflows: MD.CashflowMap = [
            transactedAt: 0,    // sell security for cash
            endPeriod: -33000,  //always flow out at end of period
        ]
        
        let md = MD(period, mv, rawCashflows)!
        XCTAssertEqual(3000, md.gainOrLoss)
        XCTAssertEqual(30000, md.averageCapital)
        XCTAssertEqual(0.1, md.performance, accuracy: 0.001)
        XCTAssertEqual(1, md.netCashflowMap.count)
    }
    
    func testLiquidateAllNearEnd() throws {
        let begPeriod = df.date(from: "2020-10-01T19:00:00Z")!  // period start
        let transactedAt = df.date(from: "2020-11-01T17:00:00Z")!  // two hours before end
        let endPeriod = df.date(from: "2020-11-01T19:00:00Z")!  // period end

        let period = DateInterval(start: begPeriod, end: endPeriod)
        let mv = MD.MarketValueDelta(start: 30000, end: 0)
        let rawCashflows: MD.CashflowMap = [
            transactedAt: 0,    // sell security for cash
            endPeriod: -33000,  //always flow out at end of period
        ]
        
        let md = MD(period, mv, rawCashflows)!
        XCTAssertEqual(3000, md.gainOrLoss)
        XCTAssertEqual(30000, md.averageCapital)
        XCTAssertEqual(0.1, md.performance, accuracy: 0.001)
        XCTAssertEqual(1, md.netCashflowMap.count)
    }
    
    func testExample() throws {
        typealias MD = ModifiedDietz<Double>
        let df = ISO8601DateFormatter()
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let mid = df.date(from: "2020-06-16T00:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!

        let period = DateInterval(start: beg, end: end)
        let mv = MD.MarketValueDelta(start: 105, end: 100)
        let cf: MD.CashflowMap = [mid: -10.0]
        let md = MD(period, mv, cf)!

        XCTAssertEqual(0.05, md.performance, accuracy: 0.001)
        //print("\(md.performance * 100)%")
    }
    
    func testConvenienceInit() throws {
        typealias MD = ModifiedDietz<Double>
        let df = ISO8601DateFormatter()
        let beg = df.date(from: "2020-06-01T12:00:00Z")!
        let mid = df.date(from: "2020-06-16T00:00:00Z")!
        let end = df.date(from: "2020-06-30T12:00:00Z")!

        let period = DateInterval(start: beg, end: end)
        let cf: MD.CashflowMap = [mid: -10.0]
        let md = MD(period: period, startValue: 105, endValue: 100, cashflowMap: cf)!

        XCTAssertEqual(0.05, md.performance, accuracy: 0.001)
        //print("\(md.performance * 100)%")
    }
}
