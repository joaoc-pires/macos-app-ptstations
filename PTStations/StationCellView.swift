//
//  StationCellView.swift
//  PTStations
//
//  Created by Joao Pires on 04/01/2022.
//

import SwiftUI

struct StationCellView: View {
    var station: Station
    var viewModel: ImportViewModel
    
    @State var name: String
    @State var line: String
    @State var parish: String
    @State var municipality: String
    @State var district: String
    @State var nodeId: String
    @State var latitude: String
    @State var longitude: String
    
    internal init(station: Station, viewModel: ImportViewModel) {
        self.station = station
        self.name = station.name
        self.line = station.line
        self.parish = station.parish
        self.municipality = station.municipality
        self.district = station.district
        self.nodeId = station.nodeId
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.viewModel = viewModel
    }

    
    var body: some View {
        HStack {
            TextField("", text: $name, prompt: nil)
                .onSubmit { station.name = name; viewModel.objectWillChange.send() }
            TextField("", text: $line, prompt: nil)
                .onSubmit { station.line = line; viewModel.objectWillChange.send()  }
            TextField("", text: $parish, prompt: nil)
                .onSubmit { station.parish = parish; viewModel.objectWillChange.send()  }
            TextField("", text: $municipality, prompt: nil)
                .onSubmit { station.municipality = municipality; viewModel.objectWillChange.send()  }
            TextField("", text: $district, prompt: nil)
                .onSubmit { station.district = district; viewModel.objectWillChange.send()  }
            TextField("", text: $nodeId, prompt: nil)
                .onSubmit { station.nodeId = nodeId; viewModel.objectWillChange.send()  }
            TextField("", text: $latitude, prompt: nil)
                .onSubmit { station.latitude = latitude; viewModel.objectWillChange.send()  }
            TextField("", text: $longitude, prompt: nil)
                .onSubmit { station.longitude = longitude; viewModel.objectWillChange.send()  }
        }
    }
}

struct StationCellView_Previews: PreviewProvider {
    static var previews: some View {
        StationCellView(station: Station(name: String(), line: String(), parish: String(), municipality: String(), destrict: String()), viewModel: ImportViewModel())
    }
}
