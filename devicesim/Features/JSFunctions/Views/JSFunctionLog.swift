//
//  JSFunctionLog.swift
//  devicesim
//
//  Created by Max Mönch on 25.05.25.
//

import SwiftUI

struct JSFunctionLog: View{
    @Bindable var viewModel: JSFunctionsAdminViewModel
    @Environment(\.globalState) var globalState

    var body: some View{
        VStack(alignment: .leading, spacing: 4) {
            Button("isDarkmode: "+String(globalState.isDarkmode)){
                globalState.isDarkmode = !globalState.isDarkmode
            }
            Text("Log Stream:")
                .font(.subheadline)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(viewModel.logStream.enumerated()), id: \.offset) { entry in
                        Text(entry.element)
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
