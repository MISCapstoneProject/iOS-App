import SwiftUI
import CoreLocation

// MARK: - ARModeView Container
struct ARModeView: View {
    @StateObject private var peopleStore = PeopleStore()
    @StateObject private var locationManager = LocationManager()
    @State private var isMapExpanded = false

    var body: some View {
        ZStack(alignment: .leading) {
            ARViewContainer(peopleStore: peopleStore)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    if isMapExpanded {
                        RadarMapView(
                            people: peopleStore.people,
                            deviceHeading: locationManager.heading
                        )
                        .frame(width: 200, height: 200)
                        .transition(.move(edge: .leading))
                    }
                    ExpandCollapseButton(isExpanded: $isMapExpanded)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Radar Map
struct RadarMapView: View {
    var people: [CGPoint]
    var deviceHeading: Double
    var detectionAngle: Double = 60

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size/2 * 0.9
            let scale  = radius / 100

            ZStack {
                // Background and border
                Circle()
                    .fill(Color.black.opacity(0.7))
                Circle()
                    .stroke(Color.green, lineWidth: size * 0.02)

                // Detection sector (always pointing up/north)
                SectorShape(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(270 - detectionAngle/2),
                    endAngle: .degrees(270 + detectionAngle/2)
                )
                .fill(Color.blue.opacity(0.3))

                // Cardinal labels around perimeter (positions rotate but text stays upright)
                ForEach([("北", 270.0), ("東", 0.0), ("南", 90.0), ("西", 180.0)], id: \ .0) { label, baseAngle in
                    let angle = -(baseAngle - deviceHeading) * .pi / 180
                    let xPos = center.x + cos(angle) * radius
                    let yPos = center.y - sin(angle) * radius
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: xPos, y: yPos)
                }

                // Person points (only their positions use heading)
                ForEach(people.indices, id: \.self) { idx in
                    let raw        = people[idx]
                    let worldAngle = atan2(raw.y, raw.x)
                    let distance   = hypot(raw.x, raw.y)
                    let adjusted   = worldAngle - deviceHeading * .pi / 180
                    let x = center.x + cos(adjusted) * distance * scale
                    let y = center.y + sin(adjusted) * distance * scale
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.05, height: size * 0.05)
                        .position(x: x, y: y)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
    }
}

// MARK: - Sector Shape
struct SectorShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Expand/Collapse Button
struct ExpandCollapseButton: View {
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            Image(systemName: isExpanded ? "chevron.left.circle.fill" : "chevron.right.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .padding()
        }
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var heading: Double = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading
        }
    }
}
