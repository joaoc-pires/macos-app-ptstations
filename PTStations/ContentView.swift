//
//  ContentView.swift
//  PTStations
//
//  Created by Joao Pires on 04/01/2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ImportViewModel()
    
    var body: some View {
        if viewModel.stations.isEmpty {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        Text("XLSX or JSON")
                            .font(.title)
                    }
                    .onTapGesture { viewModel.didTapImportXLSX() }
                    Spacer()
                }
                Spacer()
                Text("Click to import")
                Spacer()
            }
            .frame(width: 16 * 50, height: 9 * 50)
        }
        else {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.stations, id: \.self) { station in
                            StationCellView(station: station, viewModel: viewModel)
                                .opacity(viewModel.isLoading ? 0.2 : 1)
                                .allowsHitTesting(!viewModel.isLoading)
                        }
                    }
                }
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    else {
                        HStack {
                            Button(action: { viewModel.loadCPData() }) {
                                Text("Load Coordinates")
                            }
                            Button(action: { viewModel.didTapLoadNodeIds() }) {
                                Text("Load Node IDs")
                            }
                            Button(action: { viewModel.loadAmenitiesData() }) {
                                Text("Load Services")
                            }
                            Spacer()
                            Button(action: { viewModel.didTapExportJSON() }) {
                                Text("Export JSON")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(height: 50)
            }
            .frame(width: 16 * 70, height: 9 * 70)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
