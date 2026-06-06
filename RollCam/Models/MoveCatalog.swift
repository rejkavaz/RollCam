import Foundation

// A catalogue of grappling moves the athlete can tag against the video in
// Review & Tag. Grouped into categories so a long list stays navigable; each
// move carries an SF Symbol (taken from its category) for the marker rows and
// the burned-in event banners. Tag labels stay free-form strings on TagMarker,
// so adding moves here never requires a data migration.

struct BJJMove: Identifiable, Hashable {
    let name: String
    let symbol: String
    var id: String { name }
}

enum MoveCategory: String, CaseIterable, Identifiable {
    case takedowns   = "Takedowns"
    case guardWork   = "Guard"
    case passes      = "Passes"
    case sweeps      = "Sweeps"
    case submissions = "Submissions"
    case escapes     = "Escapes"
    case transitions = "Transitions"
    case outcomes    = "Outcomes"

    var id: String { rawValue }
    var label: String { rawValue }

    /// One representative SF Symbol per category (all valid on iOS 17).
    var icon: String {
        switch self {
        case .takedowns:   return "figure.martial.arts"
        case .guardWork:   return "shield"
        case .passes:      return "arrow.right"
        case .sweeps:      return "arrow.triangle.2.circlepath"
        case .submissions: return "lock.fill"
        case .escapes:     return "arrow.uturn.up"
        case .transitions: return "arrow.2.squarepath"
        case .outcomes:    return "flag.fill"
        }
    }

    var moveNames: [String] {
        switch self {
        case .takedowns:
            return ["Double leg", "Single leg", "High crotch", "Blast double", "Ankle pick",
                    "Body lock", "Arm drag", "Snap down", "Duck under", "Fireman's carry",
                    "Foot sweep", "Osoto gari", "Uchi mata", "Seoi nage", "Tomoe nage",
                    "Tani otoshi", "Hip throw", "Inside trip", "Outside trip", "Guard pull"]
        case .guardWork:
            return ["Closed guard", "Open guard", "Half guard", "Butterfly guard", "De la Riva",
                    "Reverse DLR", "Spider guard", "Lasso guard", "X-guard", "Single-leg X",
                    "Deep half", "Z-guard", "Knee shield", "Rubber guard", "50/50",
                    "Worm guard", "Collar-sleeve", "Shin-to-shin", "Williams guard", "Octopus guard"]
        case .passes:
            return ["Toreando", "Knee cut", "Over-under", "Double under", "Stack pass",
                    "Leg drag", "X-pass", "Smash pass", "Long step", "Float pass",
                    "Headquarters", "Body lock pass", "Folding pass", "Cartwheel pass",
                    "Leg weave", "Backstep pass"]
        case .sweeps:
            return ["Scissor sweep", "Hip bump", "Flower sweep", "Butterfly sweep", "Hook sweep",
                    "DLR sweep", "X-guard sweep", "Tripod sweep", "Sickle sweep", "Balloon sweep",
                    "Lumberjack sweep", "Pendulum sweep", "Waiter sweep", "Overhead sweep",
                    "Old school sweep", "Tomahawk sweep"]
        case .submissions:
            return ["Rear naked choke", "Triangle", "Armbar", "Kimura", "Americana",
                    "Guillotine", "D'arce", "Anaconda", "Omoplata", "Ezekiel",
                    "Cross-collar choke", "Bow and arrow", "Loop choke", "Clock choke",
                    "Baseball choke", "North-south choke", "Straight ankle lock", "Inside heel hook",
                    "Outside heel hook", "Kneebar", "Toe hold", "Calf slicer", "Bicep slicer",
                    "Wristlock", "Gogoplata", "Buggy choke", "Paper cutter", "Peruvian necktie"]
        case .escapes:
            return ["Upa / bridge", "Shrimp escape", "Hip escape", "Frame & reguard", "Granby roll",
                    "Back escape", "Mount escape", "Side control escape", "Knee-elbow escape",
                    "Stand up in guard", "Technical stand-up", "Wrestle-up"]
        case .transitions:
            return ["Mount", "Back control", "Side control", "Knee on belly", "North-south",
                    "Turtle", "Take the back", "Berimbolo", "Crab ride", "Leg entanglement",
                    "Saddle / 411", "Outside ashi", "Establish grips", "Break posture",
                    "Recompose guard", "Come up", "Hip switch", "Backstep", "Kipping recover"]
        case .outcomes:
            return ["Tap", "Submission", "Sweep", "Takedown", "Pass", "Position advance",
                    "Back take", "Scramble", "Bad pos", "Stalemate", "Reset", "Stand-up"]
        }
    }

    var moves: [BJJMove] { moveNames.map { BJJMove(name: $0, symbol: icon) } }
}

enum MoveCatalog {
    static var all: [BJJMove] { MoveCategory.allCases.flatMap(\.moves) }
}
