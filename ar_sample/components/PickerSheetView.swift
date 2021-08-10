//
//  PickerSheetView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/06.
//

import Foundation
import SwiftUI


struct PickerSheetView: View {
    @State var selectedObj: String = "New"
    @Binding var objs: [String]
    
    var onSelect: (String) -> Void
    var title: String
    var subtitle: String
    @Binding var enableSheet: Bool
    
    var body: some View {
        if enableSheet {
            GeometryReader { gr in
                VStack {
                    VStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        Text(subtitle)
                            .padding(.top, 5)
                        Picker("Picker", selection: $selectedObj) {
                            ForEach(objs, id: \.self) { item in
                                Text(item).tag(item)
                            }
                            Text("Create Room").tag("New")
                        }.labelsHidden()
                    }.background(RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.white).shadow(radius: 1))
                    VStack {
                        Button(action: {
                            debugPrint("Done Selected")
                            enableSheet = false
                            self.onSelect($selectedObj.wrappedValue)
                        }) {
                            Text("Done").fontWeight(Font.Weight.bold)
                        }.padding()
                            .frame(maxWidth: gr.size.width  - 90)
                            .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.white).shadow(radius: 1))

                    }
                }.position(x: gr.size.width / 2 ,y: gr.size.height - 200)
            }
        }
    }
}
