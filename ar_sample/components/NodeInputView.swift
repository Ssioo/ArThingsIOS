//
//  NodeInputView.swift
//  NodeInputView
//
//  Created by 조연우 on 2021/08/25.
//

import Foundation
import SwiftUI


struct NodeInputView: View {
    @State var name: String = ""
    @State var address: String = ""
    @State var harvestingType: String = ""
    @State var harvestingCapability: String = ""
    @Binding var isShow: Bool
    var onCancel: () -> Void
    var onSubmit: (String, String, String, String) -> Void
    
    var body: some View {
        if isShow {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.caption)
                TextField("Enter Node Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                Text("Address")
                    .font(.caption)
                TextField("Enter Node Address", text: $address)
                    .textFieldStyle(.roundedBorder)
                Text("Harvesting Type")
                    .font(.caption)
                TextField("Enter Harvesting Type", text: $harvestingType)
                    .textFieldStyle(.roundedBorder)
                Text("Harvesting Type")
                    .font(.caption)
                TextField("Enter Harvesting Capability", text: $harvestingCapability)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                HStack {
                    Button(
                        action: {
                            onCancel()
                        },
                        label: {
                            Text("Cancel")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(4)
                                .background(Color.secondary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        })
                    Button(
                        action: {
                            onSubmit(name, address, harvestingType, harvestingCapability)
                        },
                        label: {
                            Text("Add")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        })
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}
