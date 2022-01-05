//
//  ImportViewModel.swift
//  PTStations
//
//  Created by Joao Pires on 04/01/2022.
//

import AppKit
import CoreXLSX
import SwiftSoup
import Foundation
import PortugalTrains

class ImportViewModel: ObservableObject {
    @Published var stations = [Station]()
    @Published var isLoading = false
    
    func didTapImportXLSX() {
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {

            startLoading()
            let filepath = panel.url!
            DispatchQueue.global().async {
                
                if filepath.pathExtension == "xlsx" {
                    
                    self.parseXLSX(from: filepath)
                }
                if filepath.pathExtension == "json" {
                    
                    self.parseJSON(from: filepath)
                }
            }
        }
    }
        
    func didTapExportJSON() {
        
        let savePanel = NSSavePanel()
        savePanel.title = "stations.json"
        savePanel.begin { result in
            
            if result == .OK {
                
                if let panelURL = savePanel.url {
                    
                    let data = try! JSONEncoder().encode(self.stations)
                    try! data.write(to: panelURL)
                }
            }
        }
    }
    
    func parseXLSX(from filepath: URL) {
        
        let data = try! Data(contentsOf: filepath)
        guard let file = try? XLSXFile(data: data) else {
            fatalError("XLSX file at \(filepath) is corrupted or does not exist")
        }
        do {
            for wbk in try file.parseWorkbooks() {
                for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                    if let worksheetName = name {
                        print("This worksheet has a name: \(worksheetName)")
                    }
                    
                    let worksheet = try file.parseWorksheet(at: path)
                    let rows = (worksheet.data?.rows ?? [])
                    let rowCount = rows.count
                    guard rowCount > 1 else { return }
                    for i in 1 ..< rowCount {
                        
                        if let sharedStrings = try file.parseSharedStrings() {
                            
                            let row = rows[i]
                            let station = Station(
                                name: row.cells[3].stringValue(sharedStrings) ?? String(),
                                line: row.cells[2].stringValue(sharedStrings) ?? String(),
                                parish: row.cells[4].stringValue(sharedStrings) ?? String(),
                                municipality: row.cells[5].stringValue(sharedStrings) ?? String(),
                                destrict: row.cells[6].stringValue(sharedStrings) ?? String())
                            DispatchQueue.main.async {
                                
                                self.stations.append(station)
                            }
                        }
                    }
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
        endLoading()
    }
    
    func parseJSON(from filepath: URL) {
        
        startLoading()
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: filepath) else { return }
        if let stations = try? decoder.decode([Station].self, from: data) {
            
            DispatchQueue.main.async {
                
                self.stations = stations.sorted(by: { $0.name < $1.name })
            }
        }
        endLoading()
    }
    
    func didTapLoadNodeIds() {
        
        for station in stations {
            
            if station.nodeId.isEmpty {
                
                let service = StationService()
                getId(for: station.name, using: service, in: station)
            }
        }
        
    }
    
    func getId(for query: String, using service: StationService, in station: Station) {
        
        startLoading()
        guard !query.isEmpty else {
            
            endLoading()
            return
        }
        let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? query
        service.search(for: safeQuery) { result in
            
            self.endLoading()
            switch result {
                case .failure(let error): print("Failed to get info for \(query) with error: '\(error.localizedDescription)'")
                case .success(let reply):
                    let nodes = reply.response ?? []
                    if nodes.count != 1 {
                        
                        for node in nodes {
                            
                            let clearName = station.name.lowercased().replacingOccurrences(of: "-a-", with: " ")
                            if node.name?.lowercased() == station.name.lowercased() || node.name?.lowercased() == clearName {
                                
                                guard let nodeId = node.id else { return }
                                station.nodeId = String(describing: nodeId)
                                DispatchQueue.main.async {
                                    
                                    self.objectWillChange.send()
                                }
                                return
                            }
                        }
                        let newQuery = String(query.dropLast())
                        self.getId(for: newQuery, using: service, in: station)
                    }
                    else {
                        
                        guard let nodeId = nodes.first?.id else { return }
                        station.nodeId = String(describing: nodeId)
                        DispatchQueue.main.async {
                            
                            self.objectWillChange.send()
                        }
                    }
            }
        }
    }
    
    func endLoading() {
        
        DispatchQueue.main.async {
            
            self.isLoading = false
        }
    }
    
    func startLoading() {
        
        DispatchQueue.main.async {
            
            self.isLoading = true
        }
    }
    
    func loadCPData() {
        
        for station in stations {
           
            let urlExtension = station.name.replacingOccurrences(of: " ", with: "-").folding(options: .diacriticInsensitive, locale: .current).lowercased()
            let baseUrl = "https://www.cp.pt/passageiros/pt/consultar-horarios/estacoes/"
            guard let url = URL(string:"\(baseUrl)\(urlExtension)") else { continue }
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                
                guard error == nil else { return }
                guard let data = data else { return }
                guard let html = String(data: data, encoding: .utf8) else { return }
                self.parseCoordenatesFrom(html: html, for: station)
            }
            task.resume()
        }
    }
    
    func loadAmenitiesData() {
        
        for station in stations {
            
            let baseUrl = "https://servicos.infraestruturasdeportugal.pt/negocios-e-servicos/estacoes/"
            guard let url = URL(string: "\(baseUrl)\(station.nodeId)") else { continue }
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                
                print("Got result for: \(station.nodeId)")
                guard error == nil else { return }
                guard let data = data else { return }
                guard let html = String(data: data, encoding: .utf8) else { return }
                self.parseAmenitiesFrom(html: html, for: station)
            }
            task.resume()
        }
    }
    
    func parseCoordenatesFrom(html: String, for station: Station) {
        
        do {
            
            let doc: Document = try SwiftSoup.parse(html)
            let lists: Elements = try doc.select("li")
            for list in lists {
                
                var text = try list.text()
                if text.contains("Coordenadas") {
                    
                    text = text.replacingOccurrences(of: "Coordenadas: ", with: "")
                    let components = text.components(separatedBy: "|")
                    station.latitude = components.first ?? String()
                    station.longitude = components.last ?? String()
                    DispatchQueue.main.async {
                        
                        self.objectWillChange.send()
                    }
                }
            }
        }
        catch let error {
            
            print(error.localizedDescription)
        }
    }
    
    func parseAmenitiesFrom(html: String, for station: Station) {
        
        do {
            
            var amenities = [Amenity]()
            let doc: Document = try SwiftSoup.parse(html)
            let carouselItems: Elements = try doc.getElementsByClass("carousel-item")
            let lists: Elements = try carouselItems.select("p")
            for list in lists {
                
                do {
                    
                    let text = try list.text()
                    if text.contains("Cidade mais próxima") { continue }
                    amenities.append(parseAmenity(from: text))
                }
                catch {
                    
                    print(error.localizedDescription)
                    continue
                }
            }
            station.amenities = amenities
            DispatchQueue.main.async {
                
                self.objectWillChange.send()
            }
        }
        catch let error {
            
            print(error.localizedDescription)
        }

    }
    
    func parseAmenity(from text: String) -> Amenity {
        
        func parse(text: String) -> (title: String, value: String) {
            let components = text.components(separatedBy: " | ")
            var title = components.first ?? ""
            title = title.replacingOccurrences(of: "Aeroporto", with: "")
            title = title.replacingOccurrences(of: "Farmácia", with: "")
            title = title.replacingOccurrences(of: "Bombeiros", with: "")
            title = title.replacingOccurrences(of: "Polícia", with: "")
            title = title.replacingOccurrences(of: "Hospital", with: "")
            title = title.replacingOccurrences(of: "Morada", with: "")
            
            var value = components.last ?? ""
            value = value.replacingOccurrences(of: "Distância", with: "")
            value = value.replacingOccurrences(of: "Telefone", with: "")
            value = value.replacingOccurrences(of: "Morada", with: "")
            
            if value == title {
                title = String()
            }
            
            return (title, value)
        }
        
        var result = Amenity()
        if text.contains("Aeroporto") {
            
            result.type = .airport
        }
        if text.contains("Farmácia") {
            
            result.type = .pharmacy
        }
        if text.contains("Bombeiros") {
            
            result.type = .fireDepartment
        }
        if text.contains("Polícia") {
            
            result.type = .police
        }
        if text.contains("Hospital") {
            
            result.type = .hospital
        }
        if text.contains("Morada") {
            
            result.type = .address
        }
        let parsedText = parse(text: text)
        result.title = parsedText.title
        result.value = parsedText.value
        
        return result
    }
}

class Station: Codable, Hashable {
    
    internal init(name: String, line: String, parish: String, municipality: String, destrict: String) {

        self.id = UUID().uuidString
        self.name = name
        self.line = line
        self.parish = parish
        self.municipality = municipality
        self.district = destrict
        self.nodeId = String()
        self.latitude = String()
        self.longitude = String()
    }
    
    var id: String
    var name: String
    var line: String
    var parish: String
    var municipality: String
    var district: String
    var nodeId: String
    var latitude: String
    var longitude: String
    var amenities: [Amenity]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(line)
        hasher.combine(parish)
        hasher.combine(municipality)
        hasher.combine(district)
        hasher.combine(id)
    }
    
    static func == (lhs: Station, rhs: Station) -> Bool {
        lhs.id == rhs.id
    }
    
}

struct Amenity: Codable {
    var type: AmenityType?
    var title: String?
    var value: String?
}

enum AmenityType: String, Codable {
    case airport
    case pharmacy
    case fireDepartment
    case police
    case hospital
    case address
}
