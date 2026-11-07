#if FREE_RUN_LOGIC_CHECKS
import Foundation

/// 只在命令列以 FREE_RUN_LOGIC_CHECKS 編譯，不會在 App 內執行。
@main
struct FreeRunLogicChecks {
    @MainActor static func main() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let origin = Coordinate(latitude: 24.14, longitude: 120.66)
        func north(_ meters: Double) -> Coordinate {
            Coordinate(latitude: origin.latitude + meters / 111_195, longitude: origin.longitude)
        }
        func place(_ id: String, _ meters: Double) -> Place {
            Place(id: id, name: id, coordinate: north(meters), category: .bar,
                  source: "osm", sourceId: id, updatedAt: start)
        }
        let places = [place("A", 100), place("B", 300), place("C", 500)]
        var session = FreeRunSession(startedAt: start, isDemo: true)
        func receive(_ meters: Double, _ seconds: Double, accuracy: Double = 5) {
            let date = start.addingTimeInterval(seconds)
            session.receive(FreeRunSample(coordinate: north(meters), accuracy: accuracy, timestamp: date), places: places, now: date)
        }
        receive(0, 0)
        precondition(session.activeBarID == "A" && !session.hasArrived)
        precondition(session.record(at: start) == nil, "未抵達不能喝酒")
        receive(61, 10)
        precondition(session.hasArrived, "39m 應啟用")
        receive(45, 12)
        precondition(session.hasArrived, "55m 保留已抵達狀態")
        receive(39, 14)
        precondition(!session.hasArrived, "超過 60m 應停用")
        receive(100, 20, accuracy: 51)
        precondition(!session.hasAccurateLocation && session.record(at: start.addingTimeInterval(20)) == nil)
        receive(100, 21, accuracy: 50)
        precondition(session.record(at: start.addingTimeInterval(21))?.barID == "A")
        precondition(session.activeBarID == "B" && !session.canRecord("A", at: start.addingTimeInterval(4_000)))
        session.selectBar("A")
        precondition(session.activeBarID == "B", "喝過的酒吧不能再選")
        receive(300, 40)
        let distanceBeforePause = session.distanceMeters
        session.pause(at: start.addingTimeInterval(40))
        receive(400, 80)
        precondition(session.elapsed(at: start.addingTimeInterval(90)) == 40)
        precondition(session.distanceMeters == distanceBeforePause && session.record(at: start.addingTimeInterval(80)) == nil)
        precondition(session.currentCoordinate == north(400), "暫停時地圖位置仍更新")
        session.resume(at: start.addingTimeInterval(100))
        receive(300, 101)
        precondition(session.distanceMeters == distanceBeforePause, "恢復不能跨暫停空白累加距離")
        precondition(session.record(at: start.addingTimeInterval(101))?.barID == "B")
        receive(500, 120)
        precondition(session.record(at: start.addingTimeInterval(120))?.barID == "C")
        precondition(session.activeBarID == nil && session.visits.map(\.barID) == ["A", "B", "C"])
        session.finish(at: start.addingTimeInterval(130))
        precondition(session.elapsed(at: start.addingTimeInterval(200)) == 70)

        let dataDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
        let decoder = JSONCoding.makeDecoder()
        let bundledBars = try decoder.decode([Place].self, from: Data(contentsOf: dataDirectory.appendingPathComponent("taichung-bars.json")))
        let routes = try decoder.decode([PopularRoute].self, from: Data(contentsOf: dataDirectory.appendingPathComponent("taichung-demo-popular-routes.json")))
        let route = routes.first { $0.path.count >= 2 }!
        var run = FreeRunSession(startedAt: start, isDemo: true)
        let demoOrigin = FreeRunDemoScript.startCoordinate(on: route.path, places: bundledBars)!
        var journey = FreeRunDemoJourney(coordinate: demoOrigin)
        var seconds = 0.0
        func send(_ coordinate: Coordinate) {
            let date = start.addingTimeInterval(seconds)
            run.receive(FreeRunSample(coordinate: coordinate, accuracy: 5, timestamp: date), places: bundledBars, now: date)
        }
        send(journey.coordinate)
        precondition(!run.hasArrived, "示範起點應保留前往首站的移動距離")
        let passes = DrinkPassStore()
        let ticket = DrinkPassPurchase(eventName: DrinkPassMockData.event.name,
                                       option: DrinkPassMockData.event.options[0], quantity: 1)
        passes.record(ticket)
        for round in 0..<3 {
            let target = run.activeBar!.place.coordinate
            let duration = round == 0 ? FreeRunDemoScript.firstLegSeconds : FreeRunDemoScript.nextLegSeconds
            for _ in 0..<Int(duration * 10) {
                let coordinate = journey.advance(toward: target, seconds: 0.1, completedVisits: round, isPaused: false)
                seconds += 0.1
                send(coordinate)
            }
            precondition(FreeRunRules.distance(journey.coordinate, target) < FreeRunRules.arrivalMeters)
            precondition(run.hasArrived, "第 \(round + 1) 輪應在 \(duration) 秒內抵達")
            let door = journey.coordinate
            for _ in 0..<20 {
                let stopped = journey.advance(toward: target, seconds: 0.1, completedVisits: round, isPaused: false)
                precondition(FreeRunRules.distance(stopped, door) < 0.01, "抵達後須停在店門口")
            }
            let visit = run.record(at: start.addingTimeInterval(seconds))!
            var feedback = FreeRunDrinkFeedback(id: visit.id, showsTicket: true)
            feedback.advance(seconds: 2.9)
            precondition(feedback.phase == .scanning, "3 秒前不能宣告掃描成功")
            let held = journey.advance(toward: run.activeBar?.place.coordinate, seconds: 4,
                                       completedVisits: round + 1, isPaused: false, waitsForFeedback: true)
            precondition(FreeRunRules.distance(held, door) < 0.01, "掃描與回饋期間不能移動")
            feedback.advance(seconds: 0.1)
            precondition(feedback.phase == .success)
            precondition(passes.redeemCup(purchaseID: ticket.id, visitID: visit.id))
            precondition(!passes.redeemCup(purchaseID: ticket.id, visitID: visit.id), "相同喝酒紀錄不能重複扣杯")
            precondition(passes.purchases[0].remainingCups == 2 - round)
            feedback.advance(seconds: FreeRunDemoScript.successSeconds)
            precondition(feedback.phase == .complete)
            seconds += feedback.elapsed
            print("示範第 \(round + 1) 輪：\(Int(duration)) 秒抵達、停留、3 秒掃描、扣 1 杯、1 秒收起，通過")
        }
        precondition(run.uniqueBarCount == 3)
        precondition(!passes.redeemCup(purchaseID: ticket.id, visitID: UUID()), "用完酒票不可再扣")
        var pubFeedback = FreeRunDrinkFeedback(id: UUID(), showsTicket: false)
        pubFeedback.advance(seconds: FreeRunDemoScript.confettiSeconds)
        precondition(pubFeedback.phase == .complete, "pub 只播放彩帶，不顯示酒票")
        let beforePause = journey.coordinate
        let paused = journey.advance(toward: run.activeBar?.place.coordinate, seconds: 100,
                                     completedVisits: 3, isPaused: true)
        precondition(paused == beforePause, "暫停時示範不能移動")
        precondition(DrinkPassArtwork.qrCodePayload(for: ticket) == "https://tsaicy.dev")

        var realRun = FreeRunSession(startedAt: start, isDemo: false)
        realRun.receive(FreeRunSample(coordinate: origin, accuracy: 5, timestamp: start), places: places, now: start)
        let jumpedAt = start.addingTimeInterval(0.1)
        realRun.receive(FreeRunSample(coordinate: north(1_000), accuracy: 5, timestamp: jumpedAt), places: places, now: jumpedAt)
        precondition(realRun.distanceMeters == 0, "真實定位仍須排除不合理高速跳點")

        var motion = DemoFriendMotion()
        let first = motion.locations(around: origin, bars: [north(30)], at: start)
        let second = motion.locations(around: origin, bars: [north(30)], at: start.addingTimeInterval(1.5))
        precondition(first.count == 3 && Set(first.map(\.nickname)).count == 3)
        for (a, b) in zip(first, second) {
            precondition(FreeRunRules.distance(a.coordinate, b.coordinate) <= 2.11)
            precondition(b.age(at: start.addingTimeInterval(4.5)) == 3)
        }
        print("通過：推薦排除、抵達遲滯、精確度、暫停時間與距離、摘要順序、朋友移動與更新時間")
    }
}
#endif
