import SwiftUI
import Inject

struct LogPage: View {
    @ObserveInjection var inject
    @Bindable var logPageViewModel = LogPageViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Activity Log")
                    .font(.headline)
                
                Spacer(minLength: 100)
                
                Picker("", selection: $logPageViewModel.selectedCategory) {

                    Text("All").tag(Optional<LogCategory>.none)
                    
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(Optional<LogCategory>.some(category))
                    }
                }
                .pickerStyle(.segmented)
                .tint(.accentColor)
                
                Spacer(minLength: 100)
                
                Button("Clear") {
                }
                .buttonStyle(.bordered)
                
                Button("Add Log") {
                    logPageViewModel.addLog(message: "Test")
                }
                .buttonStyle(.bordered)
            }
            
            List {
                ForEach(logPageViewModel.logsSorted, id: \.id) { logMessage in
                    if logPageViewModel.selectedCategory == nil {
                        HStack{                           Text("[\(logMessage.category.rawValue)]").frame(width: 100, alignment: .leading)
                            Text("\(logMessage.timestamp.formatted(date: .numeric, time: .standard)) \(logMessage.message)")
                                .font(.system(.body, design: .monospaced))
                        }
 
                    }else{
                        Text("\(logMessage.timestamp.formatted(date: .numeric, time: .standard)) \(logMessage.message)")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
        .padding()
        .enableInjection()
    }
} 
