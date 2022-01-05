# PTStations

A simple macOS app that gathers information on the Portuguese Railway train stations, and allows the user to export it as a JSON file.

The App was mostly done for personal use, it does not follow good design principles, and there's a lot of hard coded assumptions in it's code.


## How to use

You can download the XLSX file with the list of Portuguese train stations here: https://dados.gov.pt/pt/datasets/estacoes-e-apeadeiros/

This file (as of Jan 5, 2022) is not completly up to date, but it's a start.

After loading the file into the app, you need to gather the Node IDs. These are gathered from the Infraestruturas de Portugal (IP) API. The search is not 100% accurate because the station names used in the file and in the API are not 100% match.

You can also gather the coordenates for a lot of the stations. The app will scrape the CP website to gather the needed information.

After gathering the NodeIDs the app will also allow you to scrape the IP website to gather amenities in each station.

An example of the end result can be found here: https://zeroloop.org/apis/train-stations/all.json

This is a static website, and will only ever return this JSON file.


## JSON Structure

The JSON file will have the following structure:

    [
        {
            "name": "Abrantes",
            "district": "SANTARÉM",
            "parish": "São Miguel do Rio Torto e Rossio ao Sul do Tejo",
            "municipality": "ABRANTES",
            "id": "569623FE-D78C-4FF1-814B-D5FCAB44236C",
            "nodeId": "9452001",
            "longitude": "-8.194491",
            "latitude": "39.440621",
            "line": "Linha da Beira Baixa",
            "amenities": [
                {
                    "type": "airport",
                    "title": "Lisboa",
                    "value": "> 20 Km"
                },
                {
                    "type": "pharmacy",
                    "title": "Santos",
                    "value": "< 1 Km"
                },
                {
                    "type": "fireDepartment",
                    "title": " Municipais de Abrantes",
                    "value": "241 360 670"
                },
                {
                    "type": "police",
                    "title": "GNR de Abrantes",
                    "value": "241 360 920"
                },
                {
                    "type": "hospital",
                    "title": " Dr. Manoel Constâncio",
                    "value": "241 360 700"
                },
                {
                    "type": "address",
                    "title": "",
                    "value": "Rua da Estação de Abrantes - Rossio ao Sul do Tejo - 2205-022 ABRANTES"
                }
            ]
        },
        ...
    ]

Every propery is a String, and all properties can be nil.
