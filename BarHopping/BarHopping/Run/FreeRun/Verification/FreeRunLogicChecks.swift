#if FREE_RUN_LOGIC_CHECKS
import Foundation

/// 只在命令列以 FREE_RUN_LOGIC_CHECKS 編譯，不會在 App 內執行。
@main
struct FreeRunLogicChecks {
    static func main() throws {
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
        precondition(session.record(at: start) == nil, "未抵達不能買酒")
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
        precondition(session.activeBarID == "B", "買過的酒吧不能再選")
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

        // 使用正式內附資料與與位置來源共用的純 Swift 移動器，驗證兩種倍速皆可連續三輪。
        let dataDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
        let decoder = JSONCoding.makeDecoder()
        let bundledBars = try decoder.decode([Place].self, from: Data(contentsOf: dataDirectory.appendingPathComponent("taichung-bars.json")))
        let routes = try decoder.decode([PopularRoute].self, from: Data(contentsOf: dataDirectory.appendingPathComponent("taichung-demo-popular-routes.json")))
        let route = routes.first { $0.id == "demo-route-01" }!
        for multiplier in [1.0, 5.0] {
            var run = FreeRunSession(startedAt: start, isDemo: true)
            var journey = FreeRunDemoJourney(coordinate: route.path[0])
            var seconds = 0.0
            while run.visits.count < 3 && seconds < 3_600 {
                let coordinate = journey.advance(toward: run.activeBar?.place.coordinate,
                                                 meters: FreeRunRules.demoMetersPerSecond * multiplier, isPaused: false)
                let date = start.addingTimeInterval(seconds)
                run.receive(FreeRunSample(coordinate: coordinate, accuracy: 5, timestamp: date), places: bundledBars, now: date)
                if run.hasArrived { precondition(run.record(at: date) != nil) }
                seconds += 1
            }
            precondition(run.uniqueBarCount == 3, "示範應可完成三間不同酒吧")
            print("示範 ×\(Int(multiplier))：3 輪通過，\(Int(seconds)) 個模擬秒")
        }

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
