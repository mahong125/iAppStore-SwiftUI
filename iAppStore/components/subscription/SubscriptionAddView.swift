//
//  SubscriptionAddView.swift
//  iAppStore
//
//  Created by HTC on 2021/12/27.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import SwiftUI


enum SubscripeAddAlertType: Identifiable {
    case parameterError, searchEmptyError, existCheckError
    
    var id: Int { hashValue }
}


struct SubscriptionAddView: View {
    
    @Binding var isAddPresented: Bool
    @StateObject var subModel: AppSubscripeModel
    @State private var subscripeType = 0
    @State private var subscripeIndex = 0 //记录当前选择的状态
    @State private var appleIdText: String = ""
    @State private var regionName: String = "中国"
    @State private var filterViewIsExpanded = false
    @State private var alertType: SubscripeAddAlertType?
    @StateObject private var appModel = AppDetailModel()
    
    
    var body: some View {
        
        VStack {
            HStack {
                Spacer().frame(width: 50)
                Spacer()
                Text("添加新订阅").font(.title3).fontWeight(.bold).padding([.top, .leading], 12)
                Spacer()
                Button {
                    isAddPresented = false
                } label: {
                    Text("取消").font(.body)
                }
                .frame(width: 60, height: 60, alignment: .center)
                .padding([.top, .trailing], 8)
            
            }.padding(.bottom, 20)
            
            ScrollView {
                
                HStack {
                    Text("订阅类型：").font(.footnote)
                    Picker("选择订阅类型", selection: $subscripeType) {
                                    Text("版本更新").tag(0)
                                    Text("应用上架").tag(1)
                                    Text("应用下架").tag(2)
                                }
                                .pickerStyle(.segmented)
                                .onReceive([self.subscripeType].publisher.first()) { (value) in
                                    // 切换时，清空临时数据
                                    if value != subscripeIndex, appModel.app != nil {
                                        appModel.app = nil
                                    }
                                    subscripeIndex = value
                                }
                    Spacer()
                }.padding(.bottom, 15)
                
                HStack {
                    
                    Text("App 地区：").font(.footnote)
                    
                    Button(action: {
                        filterViewIsExpanded = !filterViewIsExpanded
                    }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle").imageScale(.medium)
                            Text(regionName)
                        }.frame(height: 30)
                    }
                    
                    Spacer()
                }
                
                if filterViewIsExpanded {
                    Divider()
                    ScrollView {
                        ForEach(0..<TSMGConstants.regionTypeLists.count){index in
                            HStack{
                                let type = TSMGConstants.regionTypeLists[index]
                                if type == regionName {
                                    Text(type).padding(.horizontal).padding(.top, 10).foregroundColor(.blue)
                                } else {
                                    Text(type).padding(.horizontal).padding(.top, 10)
                                }
                                Spacer()
                                if type == regionName {
                                    Image(systemName: "checkmark").padding(.horizontal).padding(.top, 10).foregroundColor(.blue)
                                }
                            }
                            .background(Color.tsmg_systemBackground)
                            .onTapGesture {
                                // 点击筛选条件
                                let type = TSMGConstants.regionTypeLists[index]
                                withAnimation{
                                    regionName = type
                                    filterViewIsExpanded = false
                                }
                            }
                        }
                    }
                    .background(Color.tsmg_systemBackground)
                    .frame(maxHeight: 300)
                    
                    Divider()
                }
                
                if subscripeType == 1 {
                    
                    HStack {
                        Text("App ID：").font(.footnote)
                        
                        let serachBar = TextField("请输入新 App 的 App ID", text: $appleIdText, onCommit: commitSearchApp)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        if #available(iOS 15.0, *) {
                            serachBar.submitLabel(.done)
                        } else {
                            serachBar
                        }
                        
                    }.padding(.bottom, 15)
                    
                    
                } else {
                    
                    HStack {
                        
                        Text("搜索 App ：").font(.footnote)
                        
                        let serachBar = TextField("请输入 App 的 App ID", text: $appleIdText, onCommit: commitSearchApp)
                            .textFieldStyle(.roundedBorder)
                        
                        if #available(iOS 15.0, *) {
                            serachBar.submitLabel(.search)
                        } else {
                            serachBar
                        }
                        
                        Button {
                            guard appleIdText.count != 0 else {
                                alertType = .searchEmptyError
                                return
                            }
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            commitSearchApp()
                        } label: {
                            Text("搜索")
                        }
                        
                    }.padding(.bottom, 15)
                    
                    if appModel.app != nil {
                        List {
                            Text("确认此 App 就是新订阅的应用，否则请重新搜索~").font(.footnote)
                            ForEach(appModel.results, id: \.trackId) { item in
                                let index = appModel.results.firstIndex { $0.trackId == item.trackId }
                                SearchCellView(index: index ?? 0, item: item).frame(height: 110)
                            }
                        }
                        .frame(minHeight: 180)
                        .padding(.bottom, 15)
                        
                        HStack {
                            Text("当前版本：").font(.footnote)
                            Text(appModel.app?.version ?? "未知")
                            Spacer()
                        }.padding(.bottom, 15)
                    }
                    
                }
                
                Button(action: {
                    
                    if appleIdText.count == 0 || (subscripeType != 1 && appModel.app == nil) {
                        alertType = .parameterError
                        return
                    }
                    
                    // 判断当前版本是否已经存在，存在就不添加
                    if subModel.apps[appleIdText] != nil {
                        alertType = .existCheckError
                        return
                    }
                    
                    let item = AppSubscripe(appId: appleIdText, regionName: regionName, subscripeType: subscripeType, currentVersion: appModel.app?.version ?? "", newVersion: nil, startTimeStamp: Date().timeIntervalSince1970, endCheckTimeStamp: nil, isFinished: false)
                    subModel.subscripes.append(item)
                    
                    if subscripeType != 1, let app = appModel.app {
                        subModel.apps[appleIdText] = app
                    } else {
                        subModel.apps[appleIdText] = AppDetail.getNewModel(appleIdText)
                    }
                    
                    isAddPresented = false
                    
                }) {
                    Text("确认添加")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding([.leading, .trailing], 15)
                        .padding([.top, .bottom], 8)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 2))
                
                }.padding([.top, .bottom], 25)
                
            }.padding([.leading, .trailing], 12)
            
            Spacer()
        }.alert(item: $alertType) { type in
            var error = ""
            switch type {
            case .parameterError:
                error = "当前填写的参数不完整，请检查清楚~"
            case .searchEmptyError:
                error = "搜索内容不能为空~"
            case .existCheckError:
                error = "已经存在相同 App ID 的检查项，请检查确认~"
            }
            return Alert(title: Text("提示"), message: Text(error), dismissButton: .default(Text("确认")))
        }
    }
    
    func commitSearchApp() {
        if appleIdText.count > 0, subscripeType != 1 {
            appModel.searchAppData(appleIdText, nil, regionName)
        }
    }
}


//
//struct SubscriptionAddView_Previews: PreviewProvider {
//    static var previews: some View {
//        SubscriptionAddView()
//    }
//}
