//
//  GlobalState.swift
//  devicesim
//
//  Created by Max Mönch on 30.05.25.
//

import SwiftUI

@Observable
class GlobalState{
    var isDarkmode: Bool = false
}

extension EnvironmentValues{
    @Entry var globalState = GlobalState()
}


