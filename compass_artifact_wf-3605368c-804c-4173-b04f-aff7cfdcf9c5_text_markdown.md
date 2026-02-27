# iOS 26 Liquid Glass: the complete technical guide for SwiftUI and UIKit

**Liquid Glass is Apple's most ambitious design overhaul since iOS 7** — a real-time refractive material system that bends, shapes, and concentrates light rather than simply blurring it. Announced at WWDC 2025 on June 9 and shipped with iOS 26 on September 15, 2025, it spans every Apple platform simultaneously for the first time: iOS, iPadOS, macOS Tahoe, watchOS, tvOS, and visionOS. For developers, it introduces a new SwiftUI modifier (`.glassEffect()`), a container primitive (`GlassEffectContainer`), UIKit equivalents via `UIGlassEffect`, and a strict design philosophy that separates navigation chrome from content. This report covers every angle — from design philosophy through API details, code examples, fitness app patterns, performance optimization, known issues, and HIG best practices.

---

## How Apple reinvented materials at WWDC 2025

Craig Federighi and Alan Dye co-presented Liquid Glass at the 92-minute WWDC keynote. Dye called it Apple's **"broadest software design update ever,"** designed to make even simple taps feel "fun and magical." Federighi revealed that Apple's industrial design team **physically fabricated glass samples of varying opacities and lensing properties** in their studios to match the digital material to real-world glass behavior.

The design draws a direct line through Apple's visual history: from Aqua in Mac OS X, through the real-time blurs of iOS 7, the fluidity of iPhone X, the Dynamic Island, and the spatial interfaces of visionOS. Federighi explicitly stated that Liquid Glass "borrows its transparency and depth from visionOS so apps feel like part of the environment around you," and that **Apple silicon provides the computational power** the effect demands.

Five dedicated WWDC 2025 sessions cover the system: **Session 219** ("Meet Liquid Glass") defines the design principles; **Session 356** ("Get to know the new design system") covers system-wide language changes; **Session 323** ("Build a SwiftUI app with the new design") walks through SwiftUI adoption; **Session 284** covers UIKit implementation; and **Session 310** addresses AppKit on macOS.

### Why it differs fundamentally from `.ultraThinMaterial`

The older SwiftUI materials (`.ultraThinMaterial` through `.ultraThickMaterial`) and UIKit's `UIBlurEffect` styles are static Gaussian blurs that **scatter light**. Liquid Glass **bends and concentrates** light. The practical differences are substantial:

| Characteristic | Previous materials (iOS 7–18) | Liquid Glass (iOS 26) |
|---|---|---|
| Light behavior | Gaussian blur (scatter) | Real-time lensing and refraction |
| Adaptivity | Fixed light/dark appearance | Continuously adapts per-pixel to background content |
| Motion response | None | Gel-like flex, gyroscope-driven highlights, touch illumination |
| Shadow system | Static or absent | Dynamic shadows that adjust opacity based on content beneath |
| Size behavior | Uniform at all sizes | Deeper shadows and more pronounced lensing at larger sizes |
| Ambient awareness | None | Nearby color spills onto the surface and scatters into shadows |
| Appearance transitions | Fade in/out | "Materialization" — gradual modulation of light bending |

As Session 219 states directly: *"Where previous materials scattered light, this new set of materials dynamically bends, shapes, and concentrates light in real time."* Apple describes Liquid Glass as a **"new digital meta-material"** — not a blur effect, but a light-simulation system.

---

## The SwiftUI API surface for Liquid Glass

### The core modifier: `.glassEffect()`

The primary API is a single view modifier with three parameters:

```swift
func glassEffect<S: Shape>(
    _ glass: Glass = .regular,
    in shape: S = .capsule,
    isEnabled: Bool = true
) -> some View
```

The `Glass` struct provides three variants and two modifier methods:

```swift
struct Glass {
    static var regular: Glass   // Default — balanced transparency, full adaptivity
    static var clear: Glass     // Higher transparency — for bold content over rich media
    static var identity: Glass  // No effect — for conditional toggling without layout changes

    func tint(_ color: Color) -> Glass       // Semantic color tint
    func interactive() -> Glass              // iOS only: press scaling, bounce, shimmer
}
```

Method chaining is supported. A fully configured glass effect looks like:

```swift
Button("Start Workout") { beginWorkout() }
    .padding()
    .glassEffect(.regular.tint(.green).interactive(), in: .capsule)
```

The shape parameter accepts any `Shape`-conforming type: `.capsule` (default), `.circle`, `RoundedRectangle(cornerRadius: 16)`, `.ellipse`, or `.rect(cornerRadius: .containerConcentric)` for automatic alignment with container corners.

**Key behavioral details.** Text placed on glass automatically receives a **vibrant treatment** — SwiftUI adjusts color, brightness, and saturation based on the background. Small glass elements (navigation bars, tab bars) flip between light and dark appearance based on underlying content. Large elements (sidebars, menus) adapt contextually without flipping. The `.glassEffect()` modifier should be applied **last** in modifier chains for correct compositing.

### GlassEffectContainer: the coordination primitive

```swift
struct GlassEffectContainer<Content: View>: View {
    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content)
}
```

`GlassEffectContainer` is critical infrastructure — **glass cannot sample other glass**. When multiple glass elements exist in a view, the container provides a shared `CABackdropLayer` sampling region so all children composite correctly. It enables three capabilities: visual blending of overlapping shapes, consistent blur and lighting, and smooth morphing transitions between elements. The `spacing` parameter defines the **morphing threshold** — elements closer than this distance will visually merge:

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "1.circle")
            .frame(width: 80, height: 80)
            .font(.system(size: 36))
            .glassEffect()
            .offset(x: 30, y: 0)
        Image(systemName: "2.circle")
            .frame(width: 80, height: 80)
            .font(.system(size: 36))
            .glassEffect()
            .offset(x: -30, y: 0)
    }
}
```

### Morphing, unions, and transitions

Three additional modifiers control advanced glass behavior:

**`.glassEffectID(_:in:)`** associates glass elements across states for coherent morphing. Elements must share a `GlassEffectContainer`, use a common `@Namespace`, and be toggled with `withAnimation`:

```swift
@State private var isExpanded = false
@Namespace private var namespace

GlassEffectContainer(spacing: 30) {
    VStack(spacing: 30) {
        if isExpanded {
            Button { } label: { Image(systemName: "crop") }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .glassEffectID("crop", in: namespace)
        }
        
        HStack(spacing: 30) {
            if isExpanded {
                Button { } label: { Image(systemName: "flip.horizontal") }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .glassEffectID("flip", in: namespace)
            }
            
            Button {
                withAnimation(.bouncy) { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "slider.horizontal.3")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .glassEffectID("toggle", in: namespace)
            
            if isExpanded {
                Button { } label: { Image(systemName: "rotate.right") }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .glassEffectID("rotate", in: namespace)
            }
        }
    }
}
```

**`.glassEffectUnion(id:namespace:)`** manually combines glass elements that are spatially distant but should render as a unified group. **`.glassEffectTransition()`** controls appearance style: `.matchedGeometry` (default morphing), `.materialize` (material appearance animation), or `.identity` (no transition).

### Built-in button styles and system integration

Two new button styles ship with iOS 26:

```swift
Button("Cancel") { }.buttonStyle(.glass)            // Translucent, secondary actions
Button("Save")   { }.buttonStyle(.glassProminent)    // Opaque tinted, primary actions
```

System views adopt Liquid Glass automatically when recompiled with Xcode 26. `NavigationStack` bars become floating glass. `TabView` gains a collapsible glass tab bar:

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass", role: .search) {
        NavigationStack { SearchView() }
    }
}
.tabBarMinimizeBehavior(.onScrollDown)   // Shrinks tab bar when scrolling
.tabViewBottomAccessory {                 // Persistent glass view above tab bar
    HStack { Image(systemName: "play.fill"); Text("Now Playing"); Spacer() }
        .padding()
}
```

Additional new APIs include `ToolbarSpacer(.fixed, spacing: 20)` for grouping toolbar items, `.sharedBackgroundVisibility(.hidden)` to remove glass from specific toolbar items, `.scrollEdgeEffect()` for configuring content-to-bar transitions, and `.backgroundExtensionEffect()` for extending content under sidebars.

### UIKit equivalents

UIKit mirrors the SwiftUI API through `UIVisualEffectView`:

```swift
// Create and materialize glass
let effectView = UIVisualEffectView()
view.addSubview(effectView)

let glassEffect = UIGlassEffect()
glassEffect.tintColor = .systemBlue
glassEffect.isInteractive = true

UIView.animate {
    effectView.effect = glassEffect   // Triggers materialize animation
}

// Shape customization
effectView.cornerConfiguration = .fixed(16)
// Or: .containerRelative() for auto-adapting corners

// Container for multiple glass views
let containerEffect = UIGlassContainerEffect()
containerEffect.spacing = 20
let containerView = UIVisualEffectView(effect: containerEffect)
```

UIKit buttons get `.glass()` and `.prominentGlass()` configurations. Toolbars adopt Liquid Glass automatically on recompilation.

---

## Code examples for every common UI element

### Glass button with tint and interactivity

```swift
Button {
    performAction()
} label: {
    Label("Add Exercise", systemImage: "plus.circle.fill")
        .font(.headline)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
}
.glassEffect(.regular.tint(.blue).interactive(), in: .capsule)
```

### Glass card overlay

```swift
ZStack {
    Image("workout-background")
        .resizable()
        .ignoresSafeArea()
    
    VStack(alignment: .leading, spacing: 8) {
        Text("Today's Summary")
            .font(.headline)
        Text("45 min • 320 cal • 142 avg BPM")
            .font(.subheadline)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    .padding()
}
```

### Navigation bar with automatic Liquid Glass

```swift
NavigationStack {
    ScrollView {
        LazyVStack { /* workout content */ }
    }
    .navigationTitle("Workouts")
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Filter", systemImage: "line.3.horizontal.decrease") { }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Start") { }   // Automatically gets .glassProminent
        }
    }
}
// Navigation bar automatically renders as floating Liquid Glass
```

### Tab bar with minimization behavior

```swift
TabView {
    Tab("Activity", systemImage: "flame.fill") { ActivityView() }
    Tab("Workouts", systemImage: "figure.run") { WorkoutsView() }
    Tab("History", systemImage: "clock") { HistoryView() }
    Tab("Profile", systemImage: "person") { ProfileView() }
}
.tabBarMinimizeBehavior(.onScrollDown)
```

### Overlay controls with GlassEffectContainer

```swift
GlassEffectContainer {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            Button { } label: {
                Image(systemName: "backward.fill")
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive())
            
            Button { } label: {
                Image(systemName: "pause.fill")
                    .frame(width: 56, height: 56)
            }
            .glassEffect(.regular.tint(.orange).interactive(), in: .circle)
            
            Button { } label: {
                Image(systemName: "forward.fill")
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive())
        }
    }
}
```

### Custom shape glass

```swift
// Heart-shaped glass effect using a custom Shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Heart path implementation
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: width / 2, y: height * 3 / 4),
            control2: CGPoint(x: 0, y: height / 2)
        )
        path.addArc(center: CGPoint(x: width / 4, y: height / 4),
                     radius: width / 4, startAngle: .degrees(180),
                     endAngle: .degrees(0), clockwise: false)
        path.addArc(center: CGPoint(x: width * 3 / 4, y: height / 4),
                     radius: width / 4, startAngle: .degrees(180),
                     endAngle: .degrees(0), clockwise: false)
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height / 2),
            control2: CGPoint(x: width / 2, y: height * 3 / 4)
        )
        return path
    }
}

Image(systemName: "heart.fill")
    .font(.system(size: 40))
    .foregroundStyle(.red)
    .frame(width: 100, height: 100)
    .glassEffect(.regular, in: HeartShape())
```

### Backward-compatible wrapper

```swift
extension View {
    @ViewBuilder
    func adaptiveGlass(
        in shape: some Shape = Capsule(),
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = interactive ? .regular.interactive() : .regular
            self.glassEffect(glass, in: shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
        }
    }
}
```

---

## Designing a fitness app with Liquid Glass

### The layer model is non-negotiable

Apple's design philosophy enforces a strict three-layer hierarchy that fitness app developers must respect:

1. **Background layer** — wallpapers, gradient backgrounds, activity ring animations, workout imagery
2. **Content layer** — workout cards, data tables, charts, exercise lists, heart rate graphs
3. **Navigation layer** — Liquid Glass lives here exclusively: tab bars, toolbars, floating action buttons, popovers

**Workout list rows, stats grids, and data cards are content — not navigation.** Applying `.glassEffect()` to every card in a workout list creates what developer Donny Wals describes as "a super weird interface that overuses Liquid Glass." The Grow health app (App Store Editor's Choice in 173 countries) demonstrates the correct approach: glass for the navigation bar date picker and toolbar elements, solid readable backgrounds for the actual health data dashboards.

### Dark backgrounds stabilize glass legibility

UX designer Jonas Forte's case study redesigning a gym app ("Esporte Mais") with Liquid Glass found that **dark backgrounds "support Liquid Glass behavior and ensure legibility at all times."** Gradient backgrounds (purple-to-blue workout themes) make glass elements more visually interesting because the refraction picks up the color variation. Light or white backgrounds make glass nearly invisible — the effect needs contrast from below.

Activity rings are especially powerful beneath glass controls. Their vivid red/green/blue gradients refract beautifully through floating glass navigation elements. But the rings themselves must remain as opaque content — never rendered as glass.

### Workout controls with morphing state transitions

A compelling pattern for fitness apps uses `glassEffectID` to morph between workout states:

```swift
@State private var isWorkoutActive = false
@Namespace private var workoutNS

GlassEffectContainer(spacing: 40) {
    if !isWorkoutActive {
        Button {
            withAnimation(.bouncy) { isWorkoutActive = true }
        } label: {
            Label("Start Workout", systemImage: "play.fill")
                .frame(width: 160, height: 56)
        }
        .glassEffect(.regular.tint(.green).interactive(), in: .capsule)
        .glassEffectID("controls", in: workoutNS)
    } else {
        HStack(spacing: 20) {
            Button { pauseWorkout() } label: {
                Image(systemName: "pause.fill").frame(width: 50, height: 50)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID("controls", in: workoutNS)
            
            Button { stopWorkout() } label: {
                Image(systemName: "stop.fill").frame(width: 50, height: 50)
            }
            .glassEffect(.regular.tint(.red).interactive(), in: .circle)
        }
    }
}
```

The single "Start Workout" capsule morphs fluidly into separate pause/stop controls — the glass material stretches and splits with gel-like flexibility.

### Stats panel with glass toolbar overlay

```swift
NavigationStack {
    ScrollView {
        VStack(spacing: 16) {
            // Heart rate card (content layer — solid, readable)
            VStack {
                Text("Heart Rate").font(.caption).foregroundStyle(.secondary)
                Text("142").font(.system(size: 64, weight: .bold, design: .rounded))
                Text("BPM").font(.title3)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 16).fill(.background))
            
            // Workout chart (content layer)
            Chart(heartRateData) { sample in
                LineMark(x: .value("Time", sample.time),
                         y: .value("BPM", sample.bpm))
                    .foregroundStyle(.red.gradient)
            }
            .frame(height: 200)
            .padding()
        }
    }
    .navigationTitle("Workout")
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("End", systemImage: "xmark.circle.fill") { }
        }
    }
}
// Nav bar = floating Liquid Glass. Charts/stats = solid content.
```

### Accessibility is a real concern

Liquid Glass received sharp criticism from accessibility advocates. The **Nielsen Norman Group published a detailed critique** citing reduced tap targets, unpredictable controls, and poor contrast ratios that can fall below **WCAG 2.2 AA minimums (4.5:1)** on complex backgrounds. Apple responded by adding a system-wide Clear/Tinted toggle in iOS 26.1 and increasing chrome opacity in Developer Beta 3.

For fitness apps, wire in accessibility support from day one:

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    workoutControls
        .glassEffect(reduceTransparency ? .identity : .regular)
}
```

The system automatically handles three adaptations when users enable accessibility settings: **Reduce Transparency** makes glass frostier with solid backgrounds; **Increase Contrast** renders elements as predominantly black or white with strong borders; **Reduce Motion** eliminates lensing, parallax, and elastic properties. Best practice is to let the system handle these automatically rather than overriding them.

---

## Performance: when glass gets expensive and how to optimize

Liquid Glass runs real-time GPU blur and refraction via Metal. On **A15 chips and newer** with ProMotion displays, the performance impact is negligible — under 1% battery difference when implemented correctly. On **older devices (iPhone 11–13)**, developers report noticeable scroll jitter, visual lag, and measurably higher battery drain. Community testing measured up to **13% battery drain** on stressed scenarios versus roughly 1% for equivalent iOS 18 views. Certain features are hardware-gated: specular highlights on app icons require **A16 Bionic or newer**.

Five optimization strategies matter most:

- **Always use `GlassEffectContainer`** when placing multiple glass elements in a view. Without it, each element creates its own `CABackdropLayer` sampling region — duplicating expensive offscreen rendering. The container shares a single sampling region across all children, dramatically reducing GPU work.

- **Toggle with `.identity` instead of removing views.** Switching `.glassEffect(shouldShow ? .regular : .identity)` avoids layout recalculation. Adding and removing glass views triggers full re-composition.

- **Enable `.interactive()` only on tappable elements.** The interactive mode adds press scaling, bounce physics, shimmer, and touch-point illumination — all of which increase GPU work. Applying it to static labels or dense lists wastes GPU cycles.

- **Avoid continuous rotation animations on glass views.** `.animation(.linear(duration: 2).repeatForever())` is particularly expensive because the glass shape recalculates on every frame. If rotation is needed, use a `UIViewRepresentable` wrapper with `UIVisualEffectView` and `UIGlassEffect`.

- **Profile with Instruments.** Monitor GPU usage and thermal state. Keep compositing layers to **≤4 glass elements per visible screen**. Apple added a user-facing relief valve in iOS 26.1: Settings → Display & Brightness → Liquid Glass toggles between "Clear" and "Tinted" modes, with Tinted increasing opacity to reduce GPU load on older devices.

---

## Gotchas, bugs, and limitations developers have hit

Developers who shipped Liquid Glass apps in the first months surfaced several recurring issues that remain partially unresolved:

**Glass won't render over opaque backgrounds.** This is the most common first-time mistake. Existing `.background()` modifiers or custom bar appearances must be removed before `.glassEffect()` will be visible. Glass needs to sample the content beneath it — an opaque layer blocks sampling entirely.

**Hit-testing on circular glass buttons is broken.** A glass circle button only registers taps on the label content area, not the full visible glass circle. The fix is to explicitly add `.contentShape(.circle)` to expand the tap target to match the visual shape.

**Rotation animations cause shape distortion.** Applying `.rotationEffect()` to a glass view causes the glass shape to morph incorrectly during animation — the capsule warps into unexpected geometries. The only current workaround is to use UIKit's `UIVisualEffectView` with `UIGlassEffect` through a `UIViewRepresentable` bridge.

**Menu morphing starts as a rectangle.** Even when the glass effect is defined as `.circle`, morphing transitions from a `Menu` start and end as rectangles before snapping to circles. The fix: apply `.glassEffect()` to the outer `Menu` view rather than the inner label.

**Light/dark flipping causes "blinking" UI.** Apps displaying mixed-brightness content (dark photos next to light cards) cause tab bars and navigation bars to rapidly flip between light and dark appearance. This isn't technically a bug — it's the adaptive system working as designed — but it creates poor UX. No clean solution exists yet; the best mitigation is consistent background brightness across views.

**The `UIDesignRequiresCompatibility` escape hatch exists** (note: Apple misspelled it as `UIDesignRequiresCompatability` in the Info.plist key). Setting this to `YES` disables Liquid Glass system-wide in your app. It's expected to work through at least the next major iOS release. Liquid Glass adoption is **not mandatory for App Store submission**.

---

## What Apple's HIG prescribes for glass effects

Apple's updated Human Interface Guidelines codify Liquid Glass around three principles: **hierarchy** (content sits beneath; glass controls float above), **harmony** (software shapes echo hardware forms), and **consistency** (unified design language across all platforms).

The HIG is explicit about where glass belongs and where it does not. Glass is appropriate for navigation bars, toolbars, tab bars, floating action buttons, sheets, popovers, menus, and context-sensitive controls. It should **never** be applied to content-layer elements: lists, tables, media players, scrollable content, or data visualizations. Stacking glass on glass is prohibited — the material cannot sample through another glass layer.

Color tinting should carry **semantic meaning only** — a green tint for a "Start" action, red for "Stop" — not decoration. Apple advises using standard system components wherever possible, since they adopt Liquid Glass automatically. The `.regular` variant suits most contexts. The `.clear` variant is reserved for bold, high-contrast content floating over media-rich backgrounds (photos, maps, video), and requires careful contrast verification.

The HIG also mandates that the **visual silhouette of every glass element must remain identical** across all appearance modes: Default, Clear, and Tinted. This ensures users who enable the iOS 26.1 Tinted mode don't experience layout shifts. Developers should remove all custom backgrounds behind toolbars and navigation bars so the system's scroll-edge effect — a gentle dissolve of scrolling content into the background — works correctly.

For fitness apps specifically, the pattern demonstrated by Apple-featured apps like GrowPal, Tide Guide, and the watchOS 26 Workout app is consistent: **vibrant, data-dense content on solid backgrounds; glass confined to the navigational chrome that floats above it.** The Apple Research app's iOS 26 update demonstrates this in health contexts — "translucent elements highlight important information without cluttering the screen" while progress data and study metrics retain full readability on opaque surfaces.