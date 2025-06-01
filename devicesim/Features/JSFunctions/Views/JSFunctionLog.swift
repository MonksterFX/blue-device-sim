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
    @State var resetIndex: Int = 0

    var body: some View{
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Log Stream:")
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: {
                    resetIndex = logger.logStore.logs.count
                }) {
                    Text("Reset")
                        .font(.subheadline)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logger.logStore.logs[resetIndex...]) { logEntry in
                        Text(logEntry.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
        }
    }
}
