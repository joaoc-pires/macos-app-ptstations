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
