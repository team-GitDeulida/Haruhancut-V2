//import WidgetKit
//
//struct Provider: TimelineProvider {
//
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date())
//    }
//
//    func getSnapshot(
//        in context: Context,
//        completion: @escaping (SimpleEntry) -> ()
//    ) {
//        completion(SimpleEntry(date: Date()))
//    }
//
//    func getTimeline(
//        in context: Context,
//        completion: @escaping (Timeline<SimpleEntry>) -> ()
//    ) {
//        let entry = SimpleEntry(date: Date())
//        completion(Timeline(entries: [entry], policy: .never))
//    }
//}
//
//struct SimpleEntry: TimelineEntry {
//    let date: Date
//}
