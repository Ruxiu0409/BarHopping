import Foundation

struct DrinkPassEvent {
    struct Option: Identifiable {
        let id: String
        let name: String
        let price: Int
        let cups: Int
        let validity: String
    }

    struct Venue: Identifiable {
        let id: String
        let name: String
        let address: String
        let drink: String
    }

    struct Question: Identifiable {
        let id: String
        let title: String
        let answer: String
    }

    let name: String
    let tagline: String
    let dateTime: String
    let meetingPoint: String
    let routeLength: String
    let introduction: String
    let options: [Option]
    let venues: [Venue]
    let questions: [Question]

    var startingPrice: Int { options.map(\.price).min() ?? 0 }
}
