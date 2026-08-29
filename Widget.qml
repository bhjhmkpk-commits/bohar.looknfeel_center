import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// ──────────────────────────────────────────────────────────────────────────────
// Look & Feel Control Center (Option C)
// Rich visual customizer with live color swatches, glass opacity sliders,
// Hyprland blur controls, and terminal window background styles.
// ──────────────────────────────────────────────────────────────────────────────
Panel {
  id: root
  moduleName: "custom.looknfeel-center"
  ipcTarget: "looknfeel_center"

  implicitWidth: bar ? (bar.vertical ? bar.barSize : stylePill.implicitWidth) : stylePill.implicitWidth
  property string activeTerminal: "foot"     // foot | ghostty | alacritty | kitty
  property string barPalette:     "default"  // default | catppuccin-mocha | tokyo-night | nord-polar ...
  property string glassMode:      "clear"    // opaque | clear | blur
  property int    blurSize:       8          // 4, 8, 12, 16
  property real   bgOpacity:      0.50       // 0.10 to 1.00

  readonly property var footGlassOptions: [
    { id: "clear",  label: "Clear Glass",  icon: "󰤓" },
    { id: "opaque", label: "Solid Opaque", icon: "󰝤" }
  ]
  readonly property var ghosttyGlassOptions: [
    { id: "blur",   label: "Frosted Blur", icon: "󰂵" },
    { id: "clear",  label: "Clear Glass",  icon: "󰤓" },
    { id: "opaque", label: "Solid Opaque", icon: "󰝤" }
  ]
  readonly property var glassOptions: (activeTerminal === "foot") ? footGlassOptions : ghosttyGlassOptions
  property string windowOpacity:  "solid"    // solid | 0.95 | 0.90 | 0.80
  property string customBgColor:  "default"  // default | #000000 | #11111b | #1a1b26 ...
  property real   barOpacity:     0.85       // 0.00 to 1.00
  property string wallpaperCycle: "Off"      // Off | 30s | 1m | 5m | 10m | 18m | 30m
  property string barStyle:       "islands"  // islands | bar
  readonly property bool isIslandBar: root.barStyle === "islands" || (root.bar && (root.bar.moduleName === "my_floating_bar" || root.bar.moduleName === "custom.island-bar" || root.bar.moduleName === "bohar.island_bar"))
  readonly property color effectiveForeground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")
  readonly property string scriptDir: pluginDir + "/scripts"

  // ── Polling & State Refresh (Zero continuous CPU overhead) ──────────────────
  Timer {
    id: pollTimer
    interval: 10000; running: root.opened; repeat: true
    onTriggered: if (!stateProc.running) stateProc.running = true
  }

  onOpenedChanged: {
    if (root.opened && !stateProc.running) stateProc.running = true
  }

  Component.onCompleted: {
    if (!stateProc.running) stateProc.running = true
  }

  Process {
    id: stateProc
    command: ["bash", "-c",
      "export PATH=\"" + root.scriptDir + ":$HOME/.local/bin:$PATH\"; cat \"$HOME\"/.local/state/omarchy/blur-opacity-state.env 2>/dev/null || echo ''; echo '---TERM---'; if [[ -f \"$HOME/.config/xdg-terminals.list\" ]]; then grep -v '^[[:space:]]*#' \"$HOME/.config/xdg-terminals.list\" 2>/dev/null | grep -v '^[[:space:]]*$' | head -n 1; elif pgrep -x ghostty >/dev/null 2>&1; then echo 'ghostty'; elif pgrep -x foot >/dev/null 2>&1; then echo 'foot'; elif command -v ghostty >/dev/null 2>&1; then echo 'ghostty'; elif command -v foot >/dev/null 2>&1; then echo 'foot'; else echo 'foot'; fi; grep -oP 'base-size\\s*=\\s*\\K[0-9]+' \"$HOME\"/.config/omarchy/shell.toml 2>/dev/null || echo ''; omarchy-wallpaper-rotate-status 2>/dev/null || echo 'Off'; custom-omarchy-terminal-font-size 2>/dev/null || echo '11'; cat \"$HOME\"/.local/state/omarchy/toggles/bar-style 2>/dev/null || echo 'islands'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var inTermSection = false
        for (var i = 0; i < lines.length; i++) {
          var l = lines[i].trim()
          if (l === "---TERM---") {
            inTermSection = true
            continue
          }
          if (inTermSection) {
            inTermSection = false
            if (l.indexOf("ghostty") >= 0) root.activeTerminal = "ghostty"
            else if (l.indexOf("foot") >= 0) root.activeTerminal = "foot"
            else if (l.indexOf("alacritty") >= 0) root.activeTerminal = "alacritty"
            else if (l.indexOf("kitty") >= 0) root.activeTerminal = "kitty"
            continue
          }
          if (l.match(/^(off|30s|1m|5m|10m|18m|30m)$/i)) root.wallpaperCycle = l.toLowerCase()
          else if (l.match(/^[0-9]+$/)) {
            var f = parseInt(l, 10)
            if (f >= 8 && f <= 24) root.systemFontSize = f
          }
          if (l.indexOf("BAR_PALETTE=") === 0)
            root.barPalette = l.replace("BAR_PALETTE=", "").replace(/\"/g, "")
          else if (l.indexOf("BAR_OPACITY=") === 0)
            root.barOpacity = parseFloat(l.replace("BAR_OPACITY=", "").replace(/\"/g, "")) || 0.85
          else if (l.indexOf("MODE=") === 0)
            root.glassMode = l.replace("MODE=", "").replace(/\"/g, "")
          else if (l.indexOf("BLUR_SIZE=") === 0)
            root.blurSize = parseInt(l.replace("BLUR_SIZE=", "").replace(/\"/g, ""), 10) || 8
          else if (l.indexOf("BG_OPACITY=") === 0) {
            var val = l.replace("BG_OPACITY=", "").replace(/\"/g, "")
            root.bgOpacity = (val === "default") ? 0.50 : (parseFloat(val) || 0.50)
          } else if (l.indexOf("WINDOW_OPACITY=") === 0)
            root.windowOpacity = l.replace("WINDOW_OPACITY=", "").replace(/\"/g, "")
          else if (l.indexOf("BG_COLOR=") === 0)
            root.customBgColor = l.replace("BG_COLOR=", "").replace(/\"/g, "")
          else if (l === "islands" || l === "bar")
            root.barStyle = l
          else if (l.match(/^[0-9]+$/) && parseInt(l, 10) >= 8 && parseInt(l, 10) <= 24) {
            root.terminalFontSize = parseInt(l, 10)
          }
        }
        if (root.activeTerminal === "foot" && root.glassMode === "blur") {
          root.glassMode = "clear"
        }
      }
    }
  }

  // ── Execution Process ───────────────────────────────────────────────────────
  Process {
    id: execProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!stateProc.running) stateProc.running = true
      }
    }
  }

  function applyCommand(cmd) {
    execProc.command = ["bash", "-c", "export PATH=\"" + root.scriptDir + ":$HOME/.local/bin:$PATH\"; " + cmd]
    if (!execProc.running) execProc.running = true
  }

  // ── Visual Swatches Model (24 Curated Unique Themes & Colors) ──────────────
  readonly property var colorSwatches: [
    { name: "Theme Default",    color: "#1e1e2e", isDefault: true,  border: "#89b4fa" },
    { name: "OLED Pitch Black", color: "#000000", isDefault: false, border: "#333333" },
    { name: "Milk Pure White",  color: "#ffffff", isDefault: false, border: "#89b4fa" },
    { name: "Vintage Cream",    color: "#f5f2e9", isDefault: false, border: "#d4a373" },
    { name: "Warm Latte",       color: "#eff1f5", isDefault: false, border: "#df8e1d" },
    { name: "Soft Peach",       color: "#fde2e4", isDefault: false, border: "#e07a5f" },
    { name: "Pastel Lavender",  color: "#e8dff5", isDefault: false, border: "#8338ec" },
    { name: "Matcha Tea",       color: "#e2ece9", isDefault: false, border: "#588157" },
    { name: "Nord Dark Polar",  color: "#242933", isDefault: false, border: "#88c0d0" },
    { name: "Tokyo Night",      color: "#1a1b26", isDefault: false, border: "#7aa2f7" },
    { name: "Catppuccin Mocha", color: "#181825", isDefault: false, border: "#cba6f7" },
    { name: "Deep Charcoal",    color: "#11111b", isDefault: false, border: "#45475a" },
    { name: "Emerald Forest",   color: "#0d1f18", isDefault: false, border: "#a6e3a1" },
    { name: "Sage Garden",      color: "#1b2a26", isDefault: false, border: "#52b788" },
    { name: "Cyberpunk Violet", color: "#1a0f2e", isDefault: false, border: "#f38ba8" },
    { name: "Crimson Velvet",   color: "#2b0d14", isDefault: false, border: "#e63946" },
    { name: "Gruvbox Dark",     color: "#1d2021", isDefault: false, border: "#fabd2f" },
    { name: "Warm Amber Gold",  color: "#261d0f", isDefault: false, border: "#ffb703" },
    { name: "Rose Pine Moon",   color: "#232136", isDefault: false, border: "#eb6f92" },
    { name: "Oceanic Navy",     color: "#0f172a", isDefault: false, border: "#38bdf8" },
    { name: "Midnight Cyan",    color: "#082032", isDefault: false, border: "#00f5d4" },
    { name: "Electric Indigo",  color: "#18122b", isDefault: false, border: "#6366f1" },
    { name: "Dracula Purple",   color: "#21222c", isDefault: false, border: "#bd93f9" },
    { name: "Monokai Obsidian", color: "#191919", isDefault: false, border: "#a6e22e" }
  ]

  // ── Look & Feel Bar Capsule Trigger ─────────────────────────────────────────
  BorderSurface {
    id: stylePill
    anchors.fill: parent
    radius: height / 2
    color: root.opened ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22) : Color.bar.background
    borderSpec: Border.controlSpec(root.opened ? "selected" : "normal", root.barForeground, Color.accent)
    implicitWidth: styleRow.implicitWidth + Style.space(14)

    RowLayout {
      id: styleRow
      anchors.centerIn: parent
      spacing: Style.space(4)

      Text {
        text: "󰏘"
        color: Color.accent
        font.pixelSize: Style.font.body
        font.weight: Font.Bold
      }

      Text {
        text: "LOOK"
        color: root.barForeground
        font.pixelSize: Style.font.caption
        font.weight: Font.DemiBold
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggle()
    }
  }

  // ── Popup Panel ─────────────────────────────────────────────────────────────
  KeyboardPanel {
    id: popup
    anchorItem: stylePill
    bar: root.bar
    owner: root
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(440))
    contentHeight: popup.fittedContentHeight(Math.min(Style.space(820), styleCol.implicitHeight + Style.space(24)))

    ScrollView {
      id: scrollArea
      anchors.fill: parent
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: styleCol.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      Column {
        id: styleCol
        width: scrollArea.availableWidth
        spacing: Style.space(12)
        padding: 0

      // ── Header ──────────────────────────────────────────────────────────────
      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "󰏘"
          font.pixelSize: Style.font.title
          color: Color.accent
          verticalAlignment: Text.AlignVCenter
        }

        Column {
          width: parent.width - Style.space(32)
          spacing: 1

          Text {
            text: "Look & Feel Studio"
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.popups.text
          }

          Text {
            text: "Window Glass, Blur & Rice Palette"
            font.pixelSize: Style.font.caption
            color: Color.muted
          }
        }
      }

      // ── Wallpaper Rotation Interval ────────────────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Wallpaper Rotation Interval"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          Text {
            text: (root.wallpaperCycle === "off" || root.wallpaperCycle === "") ? "Off (Static)" : ("Every " + root.wallpaperCycle)
            font.pixelSize: Style.font.caption; color: Color.accent; font.bold: true
            anchors.right: parent.right
          }
        }

        // Interval timing row
        Row {
          width: parent.width; spacing: Style.space(4)

          Repeater {
            model: [
              { id: "off",  label: "Off" },
              { id: "30s",  label: "30s" },
              { id: "1m",   label: "1m" },
              { id: "5m",   label: "5m" },
              { id: "10m",  label: "10m" },
              { id: "18m",  label: "18m" },
              { id: "30m",  label: "30m" }
            ]
            delegate: BorderSurface {
              width: (parent.width - Style.space(24)) / 7; height: Style.space(24)
              radius: Style.cornerRadius
              color: (root.wallpaperCycle === modelData.id || (root.wallpaperCycle === "" && modelData.id === "off"))
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                : "transparent"
              borderSpec: Border.controlSpec(
                (root.wallpaperCycle === modelData.id || (root.wallpaperCycle === "" && modelData.id === "off")) ? "selected" : "normal",
                root.effectiveForeground,
                Color.accent
              )

              Text {
                anchors.centerIn: parent
                text: modelData.label
                font.pixelSize: Style.font.caption - 1
                color: (root.wallpaperCycle === modelData.id || (root.wallpaperCycle === "" && modelData.id === "off"))
                  ? Color.accent : Color.popups.text
                font.bold: (root.wallpaperCycle === modelData.id || (root.wallpaperCycle === "" && modelData.id === "off"))
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.wallpaperCycle = modelData.id
                  root.applyCommand("omarchy-wallpaper-rotate-set " + modelData.id)
                }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.1)
      }


      // ── Glass & Blur Modes (Visual Pill Toggles) ────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)

        Text {
          text: "Window Glass Style"
          font.pixelSize: Style.font.caption; font.bold: true; color: Color.muted
        }

        Row {
          width: parent.width; spacing: Style.space(6)

          Repeater {
            model: root.glassOptions
            delegate: BorderSurface {
              width: (parent.width - Style.space(6 * (root.glassOptions.length - 1))) / root.glassOptions.length
              height: Style.space(30)
              radius: Style.cornerRadius
              color: root.glassMode === modelData.id ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22) : "transparent"
              borderSpec: Border.controlSpec(root.glassMode === modelData.id ? "selected" : "normal", root.effectiveForeground, Color.accent)

              Row {
                anchors.centerIn: parent; spacing: Style.space(4)
                Text { text: modelData.icon; font.pixelSize: Style.font.caption; color: root.glassMode === modelData.id ? Color.accent : Color.popups.text }
                Text { text: modelData.label; font.pixelSize: Style.font.caption; color: root.glassMode === modelData.id ? Color.accent : Color.popups.text; font.bold: root.glassMode === modelData.id }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.glassMode = modelData.id
                  root.applyCommand("omarchy-blur-opacity set-mode " + modelData.id)
                }
              }
            }
          }
        }
      }

      // ── Glass Opacity Selector (Stepped Cards) ──────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)
        visible: root.glassMode !== "opaque"

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Glass Transparency"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          BorderSurface {
            anchors.right: parent.right
            height: Style.space(18); radius: height / 2
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
            borderSpec: Border.controlSpec("normal", root.effectiveForeground, Color.accent)
            implicitWidth: opacityBadgeText.implicitWidth + Style.space(10)
            Text {
              id: opacityBadgeText
              anchors.centerIn: parent
              text: Math.round(root.bgOpacity * 100) + "%"
              font.pixelSize: Style.font.caption - 1; color: Color.accent; font.bold: true
            }
          }
        }

        Grid {
          width: parent.width; columns: 4; spacing: Style.space(6)
          Repeater {
            model: [
              { val: 0.15, label: "15%", sub: "Ghost" },
              { val: 0.30, label: "30%", sub: "Subtle" },
              { val: 0.45, label: "45%", sub: "Medium" },
              { val: 0.60, label: "60%", sub: "Rich" },
              { val: 0.75, label: "75%", sub: "Heavy" },
              { val: 0.85, label: "85%", sub: "Dark" },
              { val: 0.95, label: "95%", sub: "Near-Solid" },
              { val: 1.00, label: "100%", sub: "Solid" }
            ]
            delegate: BorderSurface {
              width: (parent.width - Style.space(18)) / 4; height: Style.space(36)
              radius: Style.cornerRadius
              color: Math.abs(root.bgOpacity - modelData.val) < 0.05
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                : "transparent"
              borderSpec: Border.controlSpec(
                Math.abs(root.bgOpacity - modelData.val) < 0.05 ? "selected" : "normal",
                root.effectiveForeground,
                Color.accent
              )

              Column {
                anchors.centerIn: parent; spacing: 1
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  font.pixelSize: Style.font.caption
                  color: Math.abs(root.bgOpacity - modelData.val) < 0.05 ? Color.accent : Color.popups.text
                  font.bold: true
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.sub
                  font.pixelSize: Style.font.caption - 3
                  color: Math.abs(root.bgOpacity - modelData.val) < 0.05 ? Color.accent : Color.muted
                }
              }

              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.bgOpacity = modelData.val
                  root.applyCommand("omarchy-blur-opacity set-bg-opacity " + modelData.val.toFixed(2))
                }
              }
            }
          }
        }
      }

      // ── Frosted Blur Intensity ──────────────────────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)
        visible: root.glassMode === "blur" && root.activeTerminal !== "foot"

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Blur Passes & Radius"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          Text { text: root.blurSize + "px"; font.pixelSize: Style.font.caption; color: Color.accent; font.bold: true; anchors.right: parent.right }
        }

        Row {
          width: parent.width; spacing: Style.space(6)

          Repeater {
            model: [
              { size: 4,  label: "Subtle (4px)" },
              { size: 8,  label: "Balanced (8px)" },
              { size: 12, label: "Heavy (12px)" },
              { size: 16, label: "Deep (16px)" }
            ]
            delegate: BorderSurface {
              width: (parent.width - Style.space(18)) / 4; height: Style.space(26)
              radius: Style.cornerRadius
              color: root.blurSize === modelData.size ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22) : "transparent"
              borderSpec: Border.controlSpec(root.blurSize === modelData.size ? "selected" : "normal", root.effectiveForeground, Color.accent)

              Text {
                anchors.centerIn: parent
                text: modelData.size + "px"
                font.pixelSize: Style.font.caption
                color: root.blurSize === modelData.size ? Color.accent : Color.popups.text
                font.bold: root.blurSize === modelData.size
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.blurSize = modelData.size
                  root.applyCommand("omarchy-blur-opacity set-blur-size " + modelData.size)
                }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.1)
      }

      // ── Visual Background Color Swatches (Terminal & Surface Tint) ───────────
      Column {
        width: parent.width; spacing: Style.space(6)

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Terminal Background Tone"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          Text {
            text: root.customBgColor === "default" ? "Theme Default" : root.customBgColor.toUpperCase()
            font.pixelSize: Style.font.caption; color: Color.muted
            anchors.right: parent.right
          }
        }

        // Swatch Grid
        Grid {
          width: parent.width; columns: 4; spacing: Style.space(6)

          Repeater {
            model: root.colorSwatches
            delegate: BorderSurface {
              width: (parent.width - Style.space(12)) / 3; height: Style.space(36)
              radius: Style.cornerRadius
              color: modelData.color
              borderSpec: Border.controlSpec(
                ((modelData.isDefault && root.customBgColor === "default")) || root.customBgColor === modelData.color ? "selected" : "normal",
                root.effectiveForeground,
                Color.accent
              )

              // Active Selection Dot
              Rectangle {
                width: 6; height: 6; radius: 3
                color: Color.accent
                anchors.centerIn: parent
                visible: (modelData.isDefault && root.customBgColor === "default") || root.customBgColor === modelData.color
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var c = modelData.isDefault ? "default" : modelData.color
                  root.customBgColor = c
                  root.applyCommand("omarchy-blur-opacity set-color '" + c + "'")
                }
              }
            }
          }
        }
      }

      // ── Terminal Typography Point Size ────────────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Terminal Font Size (Foot / Ghostty / Kitty)"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          Text {
            text: root.terminalFontSize + " pt"
            font.pixelSize: Style.font.caption; color: Color.accent; font.bold: true
            anchors.right: parent.right
          }
        }

        Row {
          width: parent.width; spacing: Style.space(4)

          Repeater {
            model: [9, 10, 11, 12, 13, 14, 15, 16]
            delegate: BorderSurface {
              width: (parent.width - Style.space(28)) / 8; height: Style.space(26)
              radius: Style.cornerRadius
              color: root.terminalFontSize === modelData
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                : "transparent"
              borderSpec: Border.controlSpec(
                root.terminalFontSize === modelData ? "selected" : "normal",
                root.effectiveForeground,
                Color.accent
              )

              Text {
                text: modelData + "pt"
                font.pixelSize: Style.font.caption
                color: root.terminalFontSize === modelData ? Color.accent : Color.popups.text
                font.bold: root.terminalFontSize === modelData
                anchors.centerIn: parent
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.terminalFontSize = modelData
                  root.applyCommand("custom-omarchy-terminal-font-size " + modelData)
                }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.1)
      }

      // ── Quickshell Bar Themes & Palettes ────────────────────────────────────
      Column {
        width: parent.width; spacing: Style.space(6)

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Shell Bar Color Palette"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          Text {
            text: root.barPalette === "default" ? "Theme Default" : root.barPalette.toUpperCase()
            font.pixelSize: Style.font.caption; color: Color.accent; font.bold: true
            anchors.right: parent.right
          }
        }

        Grid {
          width: parent.width; columns: 3; spacing: Style.space(6)

          Repeater {
            model: [
              { id: "wallpaper-auto",   label: "Wallpaper Sync", icon: "", color: "#11111b", border: "#f38ba8" },
              { id: "default",          label: "Theme Default",  icon: "󰣇", color: "#1e1e2e", border: "#89b4fa" },
              { id: "vintage-cream",    label: "Vintage Cream",  icon: "󰄛", color: "#f5f2e9", border: "#d4a373" },
              { id: "milk-white",       label: "Milk White",     icon: "󰄜", color: "#ffffff", border: "#89b4fa" },
              { id: "warm-latte",       label: "Warm Latte",     icon: "󰅒", color: "#eff1f5", border: "#df8e1d" },
              { id: "soft-peach",       label: "Soft Peach",     icon: "󰄘", color: "#2e1d21", border: "#e07a5f" },
              { id: "pastel-lavender",  label: "Lavender",       icon: "󰎈", color: "#1e1829", border: "#b5a6ff" },
              { id: "matcha-tea",       label: "Matcha Tea",     icon: "󰌪", color: "#152119", border: "#84a98c" },
              { id: "amber-gold",       label: "Amber Gold",     icon: "󱁤", color: "#21180b", border: "#f59e0b" },
              { id: "crimson-velvet",   label: "Crimson Velvet", icon: "󰠲", color: "#240c11", border: "#e63946" },
              { id: "midnight-cyan",    label: "Midnight Cyan",  icon: "󰈹", color: "#081826", border: "#06b6d4" },
              { id: "electric-indigo",  label: "Indigo",         icon: "󰌌", color: "#13112c", border: "#6366f1" },
              { id: "catppuccin-mocha",  label: "Catppuccin",    icon: "󰄛", color: "#181825", border: "#cba6f7" },
              { id: "tokyo-night",       label: "Tokyo Night",   icon: "󰑣", color: "#16161e", border: "#7aa2f7" },
              { id: "nord-polar",        label: "Nord Polar",    icon: "󰋊", color: "#242933", border: "#88c0d0" },
              { id: "gruvbox-dark",      label: "Gruvbox Dark",  icon: "󱁤", color: "#1d2021", border: "#fabd2f" },
              { id: "rose-pine",         label: "Rosé Pine",     icon: "󰎈", color: "#191724", border: "#eb6f92" },
              { id: "emerald-dark",      label: "Emerald",       icon: "󰌪", color: "#0a1813", border: "#a6e3a1" },
              { id: "oled-black",        label: "OLED Black",    icon: "󰈹", color: "#000000", border: "#333333" }
            ]
            delegate: BorderSurface {
              width: (parent.width - Style.space(12)) / 3; height: Style.space(32)
              radius: Style.cornerRadius
              color: modelData.color
              borderSpec: Border.controlSpec(
                root.barPalette === modelData.id ? "selected" : "normal",
                root.effectiveForeground,
                modelData.border
              )

              Row {
                anchors.centerIn: parent; spacing: Style.space(4)
                Text { text: modelData.icon; font.pixelSize: Style.font.caption; color: modelData.border }
                Text {
                  text: modelData.label
                  font.pixelSize: Style.font.caption
                  color: root.barPalette === modelData.id ? modelData.border : (modelData.color === "#ffffff" || modelData.color === "#f5f2e9" || modelData.color === "#eff1f5" ? "#1e1e2e" : Color.popups.text)
                  font.bold: root.barPalette === modelData.id
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.barPalette = modelData.id
                  root.applyCommand("omarchy-blur-opacity set-bar-palette '" + modelData.id + "'")
                }
              }
            }
          }
        }
      }

      // ── Bar Island Transparency Level (Stepped Cards - Dynamic) ─────────────
      Column {
        width: parent.width; spacing: Style.space(6)
        visible: root.isIslandBar

        Item {
          width: parent.width; height: Style.space(16)
          Text { text: "Shell Bar Island Transparency"; font.pixelSize: Style.font.caption; font.bold: true; color: Color.popups.text; anchors.left: parent.left }
          BorderSurface {
            anchors.right: parent.right
            height: Style.space(18); radius: height / 2
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
            borderSpec: Border.controlSpec("normal", root.effectiveForeground, Color.accent)
            implicitWidth: barOpacityBadgeText.implicitWidth + Style.space(10)
            Text {
              id: barOpacityBadgeText
              anchors.centerIn: parent
              text: root.barOpacity === 0 ? "Full Glass" : (Math.round(root.barOpacity * 100) + "%")
              font.pixelSize: Style.font.caption - 1; color: Color.accent; font.bold: true
            }
          }
        }

        Grid {
          width: parent.width; columns: 3; spacing: Style.space(6)
          Repeater {
            model: [
              { val: 0.00, label: "Full Glass", sub: "0% Clear" },
              { val: 0.15, label: "Ultra Glass", sub: "15% Tint" },
              { val: 0.35, label: "Translucent", sub: "35% Tint" },
              { val: 0.55, label: "Semi Glass", sub: "55% Tint" },
              { val: 0.85, label: "Frosted Bar", sub: "85% Tint" },
              { val: 1.00, label: "Solid Bar", sub: "100% Solid" }
            ]
            delegate: BorderSurface {
              width: (parent.width - Style.space(12)) / 3; height: Style.space(38)
              radius: Style.cornerRadius
              color: Math.abs(root.barOpacity - modelData.val) < 0.06
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                : "transparent"
              borderSpec: Border.controlSpec(
                Math.abs(root.barOpacity - modelData.val) < 0.06 ? "selected" : "normal",
                root.effectiveForeground,
                Color.accent
              )

              Column {
                anchors.centerIn: parent; spacing: 1
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  font.pixelSize: Style.font.caption - 1
                  color: Math.abs(root.barOpacity - modelData.val) < 0.06 ? Color.accent : Color.popups.text
                  font.bold: true
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.sub
                  font.pixelSize: Style.font.caption - 3
                  color: Math.abs(root.barOpacity - modelData.val) < 0.06 ? Color.accent : Color.muted
                }
              }

              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.barOpacity = modelData.val
                  root.applyCommand("omarchy-blur-opacity set-bar-opacity " + modelData.val.toFixed(2))
                }
              }
            }
          }
        }

        // Bottom spacer to ensure panel bottom boundary has breathing space
        Item {
          width: parent.width
          height: Style.space(16)
        }
      }
    }
  }
}
}
