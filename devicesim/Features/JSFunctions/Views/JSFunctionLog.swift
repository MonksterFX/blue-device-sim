//
//  JSFunctionLog.swift
//  devicesim
//
//  Created by Max Mönch on 25.05.25.
//

import SwiftUI

struct JSFunctionLog: View{
    @Environment(\.globalState) var globalState
    let logger = LogManager.shared.logger(for: .jsEngine)

    var body: some View{
        VStack(alignment: .leading, spacing: 4) {
            Text("Log Stream:")
                .font(.subheadline)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logger.logStore.logs) { logEntry in
                        Text(logEntry.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.frame(maxWidth: .infinity)
            }.frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
        }
    }
}
