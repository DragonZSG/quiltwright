# Block Vector Editor Design

## Goal

Build the first Quiltwright feature: a shared macOS and iOS block-level vector editor for designing quilt blocks with real finished dimensions, pieced seam editing, applique overlays, smoothing controls, and validation-ready geometry.

## Context

Quiltwright currently has a compact architecture. `QuiltwrightUI` owns shared SwiftUI views and simple presentation data. `QuiltwrightMac` and `QuiltwrightiOS` are thin platform app entry targets. There is no persistence, sync, domain, or service layer yet.

The first feature should stay inside `QuiltwrightUI` and replace the welcome screen with a usable block designer. Local save, iCloud sync, fabric and color assignment, cutting guide UI, PDF export, image tracing, SVG import, and full quilt layout design are intentionally deferred.

## Comparable Product Research

Comparable quilt and design tools suggest these patterns:

- PreQuilt emphasizes a Block Maker, built-in shapes, SVG import, fabric links, tracing from images, fabric swatches, and fabric calculation: `https://prequilt.com/`
- Electric Quilt separates drawing tools by construction purpose and requires closed patches for fill/cutting behavior: `https://support.electricquilt.com/articles/choosing-the-right-tools-for-you/`
- Quiltler emphasizes touch-first design, custom cuts, rulers, transformations, iCloud sync, PDF export, and quilt-size workflows: `https://quiltler.com/`
- Patchwork Studio and StitchLogic emphasize fabric previews, cutting guides, drag/drop swapping, undo, and project organization: `https://www.patchworkstudio.app/` and `https://www.stitchlogic.app/`

For Quiltwright's first feature, the useful takeaways are construction-aware drawing modes, real physical dimensions, closure validation, direct manipulation, platform-adaptive tool chrome, and explicit shape roles for future cutting guides.

## Scope

In scope:

- Blank block canvas.
- Fully configurable block width and height.
- Inches and centimeters.
- Locked and unlocked aspect ratio.
- Auto-size assistant based on full quilt size presets or custom quilt size.
- Standard quilt size fudging when a locked-ratio block does not divide cleanly into a chosen quilt size.
- Pieced and applique content in the same block.
- Explicit shape role tracking: `pieced` or `applique`.
- Pieced base edited through real-time valid seam/divider paths.
- Applique overlay shapes from predefined shapes and freehand drawing.
- Auto-smooth and exact drawing modes.
- Closed-shape validation.
- Shared SwiftUI editor for macOS and iOS.
- Executable SwiftPM checks for model behavior.

Out of scope:

- Local save.
- iCloud sync.
- Fabric assignment.
- Color assignment.
- Cutting guide UI.
- PDF, print, or export.
- Seam allowance visualization.
- Border, sashing, binding, and full quilt layout preview.
- Image tracing.
- SVG import.
- Full arbitrary boolean geometry for freeform pieced shapes.

## Product Decisions

The editor uses a pieced base plus applique overlay model.

Pieced content is edited as seam or divider paths that split the finished block into valid regions. This keeps pieced mode valid by construction: no gaps, no overlaps, and no independent pieced shapes floating outside the block partition.

Applique content is placed above the pieced base as closed shapes. Applique shapes may overlap the pieced base and each other.

Every generated or authored shape has an explicit construction role. Pieced regions are tagged as `pieced`; applique shapes are tagged as `applique`. Future cutting guide logic can use that role directly instead of inferring construction behavior from layer position or geometry.

## Physical Sizing

The block document stores physical finished dimensions, not only an aspect ratio.

The sizing model supports:

- Width.
- Height.
- Unit: inches or centimeters.
- Aspect lock enabled or disabled.
- A normalized canvas coordinate space for rendering and gesture math.
- A physical coordinate space for dimensions and future cutting output.

When aspect ratio is locked, changing one side updates the other side. When aspect ratio is unlocked, width and height can be edited independently.

The visual canvas scales to available screen space on macOS and iOS. Scaling does not change the stored finished dimensions.

## Quilt Size Assistant

The editor includes a lightweight sizing assistant, not a full quilt layout designer.

The assistant inputs are:

- Standard quilt size preset or custom quilt size.
- Blocks across.
- Blocks down.
- Aspect lock state.
- Target block ratio when aspect lock is enabled.

The assistant outputs:

- Finished block width.
- Finished block height.
- Adjusted full quilt width and height when a locked-ratio block does not divide cleanly into the selected quilt size.

Standard quilt presets are editable in-place for the current sizing operation. This allows a "queen-ish" or "throw-ish" quilt size adjusted to preserve block ratio without adding a full preset management feature.

The assistant does not model borders, sashing, binding, or mixed block layouts in this first feature.

## Seam Allowance

Pieced regions have a derived cutting outline with a `1/4 inch` seam allowance around each individual pieced piece.

The seam allowance rule applies only to pieced regions. Applique shapes do not receive automatic seam allowance.

The first feature stores and verifies the rule in the model:

- `piecedSeamAllowance = 0.25 inches`.
- Pieced cutting dimensions are derived from the finished pieced region plus the seam allowance.
- Applique cutting dimensions are derived from the applique shape itself.

Cutting guide UI and export are deferred, so the first feature does not need to render or print seam allowance outlines.

## Geometry Rules

The pieced base starts as one rectangular region matching the configured block dimensions.

Pieced edits are seam or divider paths:

- A seam must start and end on valid anchors.
- Valid anchors are block boundaries, existing seam endpoints, or existing seam intersections.
- The editor snaps seam endpoints to the closest valid anchors.
- The editor previews invalid gestures without committing them.
- A committed seam must split one or more existing regions while preserving a complete block partition.
- A committed pieced base must have no gaps and no overlaps.

For the first feature, real-time enforcement should focus on practical seam paths that can be validated reliably:

- Straight line seams.
- Simple snapped divider paths.
- Existing seam intersection handling.

Curved pieced seams can be represented in the model later, but robust curved-region splitting is not required in the first implementation.

## Applique Rules

Applique mode supports predefined closed shapes:

- Rectangle.
- Triangle.
- Circle or ellipse.
- Half-circle.
- Diamond.

Applique mode also supports freehand drawing.

Freehand applique paths may be open during drawing. A path must be closed before it can be committed as a valid applique shape. The editor should surface closure problems through validation state rather than silently saving an unusable shape.

## Smoothing

Drawing mode is stored per authored shape.

Auto-smooth is the default. When confidence is high, auto-smooth normalizes recognizable drawn forms into clean geometry:

- Circle or ellipse.
- Half-circle.
- Straight line.
- Rectangle-like polygon.
- Triangle-like polygon.

When confidence is low, auto-smooth keeps the shape as a smoothed Bezier path.

Exact mode preserves the user's raw path with minimal cleanup. Exact mode still requires closed applique shapes before commit or before the block can pass validation.

## UI Direction

The first editor replaces `WelcomeView` as the app's primary screen.

Shared editor pieces live in `QuiltwrightUI`:

- `BlockDesignerView`.
- Canvas view.
- Tool controls.
- Inspector or settings content.
- Model-owned validation state.

macOS layout:

- Persistent tool rail.
- Center canvas.
- Right inspector for dimensions, units, aspect lock, mode, smoothing, and sizing assistant.

iOS layout:

- Full canvas emphasis.
- Bottom tool tray.
- Sheets for dimensions, units, aspect lock, mode, smoothing, and sizing assistant.

The layout adapts to available size while preserving one shared document model and one shared editing behavior model.

## Architecture

Add shared types in `Sources/QuiltwrightUI`.

Primary model responsibilities:

- `BlockDocument`: finished dimensions, unit, aspect lock, sizing settings, pieced seam graph, applique shapes, editor metadata, validation access.
- `BlockSize`: width, height, unit conversion, aspect-lock behavior.
- `MeasurementUnit`: inches and centimeters.
- `QuiltSizePreset`: standard quilt sizes and custom adjusted sizes.
- `BlockSizingAssistant`: block-size derivation from quilt size and grid count, including adjusted quilt dimensions for locked ratios.
- `PiecedGeometry`: seam graph, valid anchors, region derivation, seam commit validation, pieced seam allowance metadata.
- `AppliqueShape`: predefined and freehand closed paths, smoothing/exact metadata, construction role.
- `BlockValidation`: open applique paths, invalid seam attempts, sizing issues, and block validity summary.
- `BlockDesignerView`: shared SwiftUI editor surface.

`QuiltwrightMac` and `QuiltwrightiOS` stay thin and render `BlockDesignerView`.

No new Swift package dependencies, targets, deployment targets, persistence layers, networking layers, or service layers are required for the first feature.

## Data Flow

The editor owns a `BlockDocument` value or observable state object in `QuiltwrightUI`.

Gesture flow:

1. User selects a tool.
2. Canvas receives a gesture in normalized canvas coordinates.
3. Tool state converts normalized coordinates into document geometry.
4. Pieced gestures snap to valid anchors before commit.
5. Applique gestures produce closed predefined shapes or validate closure for freehand paths.
6. The document updates.
7. Validation state derives from the updated document.
8. SwiftUI re-renders the canvas and controls.

Sizing flow:

1. User edits block dimensions directly or opens the sizing assistant.
2. Direct edits update `BlockSize` according to unit and aspect-lock rules.
3. Assistant edits derive block dimensions from quilt size and grid count.
4. Locked-ratio assistant output may include adjusted quilt dimensions.
5. Canvas scale changes visually while document geometry remains physically meaningful.

## Validation And Errors

The editor should avoid destructive or surprising corrections.

For pieced mode:

- Valid snaps are previewed before commit.
- Invalid seam gestures show a validation indication and do not commit.
- The model preserves the last valid pieced base.

For applique mode:

- Predefined shapes are valid on creation.
- Freehand open paths are allowed while drawing.
- Open paths cannot become valid committed applique shapes.
- Exact mode does not bypass closure validation.

For sizing:

- Width and height must be positive.
- Grid counts must be positive integers.
- Unit conversion must preserve physical size.
- Adjusted quilt sizes must be surfaced when the locked block ratio cannot match the chosen quilt dimensions exactly.

## Verification

Add executable checks under `Tests/QuiltwrightChecks` for pure model behavior.

Required checks:

- Unit conversion between inches and centimeters.
- Aspect-lock resizing updates the opposite side.
- Unlocked resizing preserves the untouched side.
- Quilt-size assistant derives block size from quilt size and grid count.
- Quilt-size assistant returns adjusted quilt dimensions when locked ratio requires fudging.
- Pieced seam allowance is `0.25 inches`.
- Pieced regions use the seam allowance rule.
- Applique shapes do not use the pieced seam allowance rule.
- Open applique paths fail validation.
- Closed applique paths pass closure validation.
- Smoothing mode metadata is preserved.
- Exact mode metadata is preserved.

Run `swift run QuiltwrightChecks` after shared model or UI changes. Run `script/ci.sh all` before considering the implementation complete because the feature affects both macOS and iOS builds.

## Approval Checkpoints

Ask before:

- Adding persistence, local save, CloudKit, iCloud sync, or SwiftData.
- Adding dependencies.
- Adding new targets, products, schemes, or platform modules.
- Changing deployment targets.
- Adding fabric or color assignment.
- Adding cutting guide UI or export.
- Expanding the feature into a full quilt layout designer.

## Current Approval State

The user approved:

- Block-level vector editor first.
- Local save and sync out of scope.
- Fabric and color assignment out of scope.
- Pieced mode and applique mode can coexist in one block.
- Option B: pieced base plus applique overlay.
- Explicit construction role tracking for future cutting guides.
- Shared macOS and iOS editor with platform-specific chrome.
- Real-time pieced enforcement through snapping to valid seam edits.
- Fully configurable physical canvas dimensions.
- Inches and centimeters.
- Locked and unlocked aspect ratio.
- Auto-size assistant based on quilt size presets or custom quilt size.
- Fudged standard quilt size output when locked-ratio blocks do not divide cleanly.
- `1/4 inch` seam allowance for pieced pieces only.
