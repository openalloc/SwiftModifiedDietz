//
//  ModifiedDietz+Description.swift
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


extension ModifiedDietz: CustomStringConvertible {
    public var description: String {
        var buffer: [String] = []
        buffer.append("NetCashFlowMap:")
        netCashflowMap.forEach {
            buffer.append("\($0)")
        }
        buffer.append(String(format: "mv.start %.0f", marketValue.start as! CVarArg))
        buffer.append(String(format: "mv.end %.0f", marketValue.end as! CVarArg))
        buffer.append(String(format: "netCashflowTotal %.0f", netCashflowTotal as! CVarArg))
        buffer.append(String(format: "gainOrLoss %.0f", gainOrLoss as! CVarArg))
        buffer.append(String(format: "adjustedNetCashflow %.0f", adjustedNetCashflow as! CVarArg))
        buffer.append(String(format: "averageCapital %.0f", averageCapital as! CVarArg))
        buffer.append("period=\(period)")
        buffer.append("adjustedPeriod=\(adjustedPeriod)")
        buffer.append("dates=\(orderedCashflowDates)")
        buffer.append(String(format: "performance %.1f%%", 100.0 * performance as! CVarArg))
        return buffer.joined(separator: "\n")
    }
}
