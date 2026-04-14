import Foundation
import SceneKit

// MARK: - Circuit Simulator Engine

/// Represents an electronic component in the simulator
struct SimulatedComponent: Identifiable, Codable {
    let id: String
    var type: ComponentType
    var position: GridPosition
    var rotation: Int // 0, 90, 180, 270 degrees
    var value: Double // resistance in Ω, capacitance in F, voltage in V, etc.
    var isConnected: Bool

    enum ComponentType: String, Codable, CaseIterable {
        case battery
        case resistor
        case led
        case capacitor
        case wire
        case switchToggle
        case buzzer
        case potentiometer
        case transistor
        case diode
        case fuse
        case motor

        var defaultValue: Double {
            switch self {
            case .battery: return 5.0 // 5V
            case .resistor: return 220.0 // 220Ω
            case .led: return 2.0 // 2V forward voltage
            case .capacitor: return 0.0001 // 100µF
            case .wire: return 0.001 // ~0Ω
            case .switchToggle: return 0 // 0 = open, 1 = closed
            case .buzzer: return 100.0 // 100Ω equivalent
            case .potentiometer: return 10000.0 // 10kΩ max
            case .transistor: return 100.0 // hFE
            case .diode: return 0.7 // forward voltage
            case .fuse: return 1.0 // 1A rating
            case .motor: return 50.0 // 50Ω equivalent
            }
        }

        var icon: String {
            switch self {
            case .battery: return "battery.100"
            case .resistor: return "line.3.horizontal"
            case .led: return "lightbulb.fill"
            case .capacitor: return "rectangle.split.2x1"
            case .wire: return "line.diagonal"
            case .switchToggle: return "switch.2"
            case .buzzer: return "speaker.wave.2.fill"
            case .potentiometer: return "dial.low.fill"
            case .transistor: return "cpu"
            case .diode: return "arrow.right.circle"
            case .fuse: return "bolt.slash.fill"
            case .motor: return "gear"
            }
        }

        var displayName: String {
            switch self {
            case .battery: return "Battery"
            case .resistor: return "Resistor"
            case .led: return "LED"
            case .capacitor: return "Capacitor"
            case .wire: return "Wire"
            case .switchToggle: return "Switch"
            case .buzzer: return "Buzzer"
            case .potentiometer: return "Potentiometer"
            case .transistor: return "Transistor"
            case .diode: return "Diode"
            case .fuse: return "Fuse"
            case .motor: return "Motor"
            }
        }

        var color: String {
            switch self {
            case .battery: return "22C55E"
            case .resistor: return "8B5CF6"
            case .led: return "EF4444"
            case .capacitor: return "3B82F6"
            case .wire: return "94A3B8"
            case .switchToggle: return "F59E0B"
            case .buzzer: return "EC4899"
            case .potentiometer: return "14B8A6"
            case .transistor: return "6366F1"
            case .diode: return "F97316"
            case .fuse: return "EAB308"
            case .motor: return "64748B"
            }
        }
    }

    init(type: ComponentType, position: GridPosition, rotation: Int = 0) {
        self.id = UUID().uuidString
        self.type = type
        self.position = position
        self.rotation = rotation
        self.value = type.defaultValue
        self.isConnected = false
    }
}

struct GridPosition: Codable, Equatable, Hashable {
    var row: Int
    var col: Int

    static func == (lhs: GridPosition, rhs: GridPosition) -> Bool {
        lhs.row == rhs.row && lhs.col == rhs.col
    }
}

// MARK: - Connection
struct CircuitConnection: Codable, Identifiable {
    let id: String
    let fromComponentId: String
    let toComponentId: String
    let fromPin: Int // 0 = positive/input, 1 = negative/output
    let toPin: Int

    init(from: String, fromPin: Int, to: String, toPin: Int) {
        self.id = UUID().uuidString
        self.fromComponentId = from
        self.toComponentId = to
        self.fromPin = fromPin
        self.toPin = toPin
    }
}

// MARK: - Circuit State
enum CircuitState {
    case incomplete      // Not all components connected
    case open            // Switch open or missing connection
    case closed          // Complete circuit, current flowing
    case shortCircuit    // Direct battery short
    case overload        // Component exceeding rating
    case reversed        // Wrong polarity (LED/diode)
}

// MARK: - Simulation Result
struct SimulationResult {
    var state: CircuitState
    var totalVoltage: Double
    var totalResistance: Double
    var totalCurrent: Double
    var componentCurrents: [String: Double] // componentId -> current in Amps
    var componentVoltages: [String: Double] // componentId -> voltage drop
    var warnings: [String]
    var failures: [ComponentFailure]
}

struct ComponentFailure {
    let componentId: String
    let type: FailureType
    let description: String

    enum FailureType {
        case burnedOut      // LED without resistor, overcurrent
        case shortCircuit   // Direct short
        case wrongPolarity  // LED/diode reversed
        case blown          // Fuse blown
        case overheated     // Resistor power exceeded
    }
}

// MARK: - Circuit Simulator
class CircuitSimulator {

    func simulate(components: [SimulatedComponent], connections: [CircuitConnection]) -> SimulationResult {
        var warnings: [String] = []
        var failures: [ComponentFailure] = []
        var componentCurrents: [String: Double] = [:]
        var componentVoltages: [String: Double] = [:]

        // Find battery (voltage source)
        guard let battery = components.first(where: { $0.type == .battery }) else {
            return SimulationResult(
                state: .incomplete,
                totalVoltage: 0, totalResistance: 0, totalCurrent: 0,
                componentCurrents: [:], componentVoltages: [:],
                warnings: ["No battery found"], failures: []
            )
        }

        let voltage = battery.value

        // Check for open switches
        let openSwitches = components.filter { $0.type == .switchToggle && $0.value == 0 }
        if !openSwitches.isEmpty {
            return SimulationResult(
                state: .open,
                totalVoltage: voltage, totalResistance: .infinity, totalCurrent: 0,
                componentCurrents: [:], componentVoltages: [:],
                warnings: ["Switch is open — no current flowing"], failures: []
            )
        }

        // Calculate total resistance (simplified: series circuit assumption)
        var totalResistance: Double = 0
        var hasLED = false
        var hasResistorBeforeLED = false
        var ledVoltage: Double = 0

        for component in components where component.type != .battery && component.type != .wire {
            switch component.type {
            case .resistor, .buzzer, .motor:
                totalResistance += component.value
                hasResistorBeforeLED = true
            case .led:
                hasLED = true
                ledVoltage = component.value
                totalResistance += 10 // LED internal resistance ~10Ω
            case .potentiometer:
                totalResistance += component.value * 0.5 // assume midpoint
            case .capacitor:
                break // capacitors in DC steady state = open circuit (simplified)
            case .fuse:
                totalResistance += 0.1 // near zero
            case .diode:
                ledVoltage += component.value
            default:
                break
            }
        }

        // Check for short circuit
        if totalResistance < 1.0 && !components.allSatisfy({ $0.type == .battery || $0.type == .wire }) {
            return SimulationResult(
                state: .shortCircuit,
                totalVoltage: voltage, totalResistance: totalResistance,
                totalCurrent: voltage / max(0.001, totalResistance),
                componentCurrents: [:], componentVoltages: [:],
                warnings: ["Short circuit detected! Very high current flowing."],
                failures: [ComponentFailure(componentId: battery.id, type: .shortCircuit, description: "Battery short circuit — dangerous!")]
            )
        }

        // LED without resistor check
        if hasLED && !hasResistorBeforeLED {
            let ledCurrent = (voltage - ledVoltage) / 10.0 // only LED internal resistance
            if ledCurrent > 0.025 { // > 25mA
                failures.append(ComponentFailure(
                    componentId: components.first(where: { $0.type == .led })?.id ?? "",
                    type: .burnedOut,
                    description: "LED burned out! No current-limiting resistor."
                ))
                warnings.append("LED needs a resistor to limit current!")
            }
        }

        // Calculate current (Ohm's Law)
        let effectiveVoltage = voltage - ledVoltage
        let totalCurrent = totalResistance > 0 ? effectiveVoltage / totalResistance : 0

        // Calculate per-component values
        for component in components {
            switch component.type {
            case .battery:
                componentCurrents[component.id] = totalCurrent
                componentVoltages[component.id] = voltage
            case .resistor:
                componentCurrents[component.id] = totalCurrent
                componentVoltages[component.id] = totalCurrent * component.value
                // Check power dissipation (P = I²R)
                let power = totalCurrent * totalCurrent * component.value
                if power > 0.25 { // typical 1/4W resistor
                    warnings.append("Resistor \(Int(component.value))Ω is dissipating \(String(format: "%.2f", power))W — may overheat!")
                }
            case .led:
                componentCurrents[component.id] = totalCurrent
                componentVoltages[component.id] = component.value
            case .fuse:
                componentCurrents[component.id] = totalCurrent
                if totalCurrent > component.value {
                    failures.append(ComponentFailure(
                        componentId: component.id,
                        type: .blown,
                        description: "Fuse blown! Current (\(String(format: "%.2f", totalCurrent))A) exceeded rating (\(String(format: "%.1f", component.value))A)"
                    ))
                }
            default:
                componentCurrents[component.id] = totalCurrent
                componentVoltages[component.id] = totalCurrent * component.value
            }
        }

        let state: CircuitState = failures.isEmpty ? .closed : .overload

        return SimulationResult(
            state: state,
            totalVoltage: voltage,
            totalResistance: totalResistance,
            totalCurrent: totalCurrent,
            componentCurrents: componentCurrents,
            componentVoltages: componentVoltages,
            warnings: warnings,
            failures: failures
        )
    }
}
