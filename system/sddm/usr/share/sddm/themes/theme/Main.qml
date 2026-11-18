import QtQuick 2.15

// The login screen is the applied theme's own: theme-picker (~/projects/the-sky, docs/desktop.md)
// writes it to /var/lib/dotfiles/sddm/Face.qml next to the background, and it uses SDDM's context
// (sddm, userModel, sessionModel, screenModel, config) itself. Without one, or if it fails to load, a
// plain screen that belongs to no theme: the background, and a user and password line in the middle.
Rectangle {
    id: root
    width: 640
    height: 480
    color: "#000000"

    Loader {
        id: face
        anchors.fill: parent
        source: config.stringValue("face")
        focus: status === Loader.Ready
    }

    Loader {
        anchors.fill: parent
        active: face.status !== Loader.Ready && face.status !== Loader.Loading
        focus: active
        sourceComponent: plain
    }

    Loader {
        active: config.boolValue("hideCursor")
        anchors.fill: parent
        sourceComponent: MouseArea {
            enabled: false
            cursorShape: Qt.BlankCursor
        }
    }

    Component {
        id: plain

        Item {
            id: screen

            readonly property int usernameRole: Qt.UserRole + 1
            readonly property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
            readonly property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
            property bool failed: false

            Connections {
                target: sddm
                function onLoginFailed() {
                    password.clear()
                    screen.failed = true
                    password.forceActiveFocus()
                }
            }

            Image {
                anchors.fill: parent
                source: config.stringValue("background")
                fillMode: Image.PreserveAspectCrop
            }

            Column {
                anchors.centerIn: parent
                spacing: 12

                TextInput {
                    id: username
                    width: 320
                    color: "#ffffff"
                    font.pixelSize: 20
                    text: userModel.lastUser || userModel.data(userModel.index(screen.userIndex, 0), screen.usernameRole)
                    KeyNavigation.tab: password
                    onAccepted: password.forceActiveFocus()
                }

                TextInput {
                    id: password
                    width: 320
                    color: screen.failed ? "#ff6060" : "#ffffff"
                    font.pixelSize: 20
                    echoMode: TextInput.Password
                    focus: true
                    KeyNavigation.tab: username
                    onTextEdited: screen.failed = false
                    onAccepted: sddm.login(username.text, password.text, screen.sessionIndex)
                    Component.onCompleted: forceActiveFocus()
                }
            }
        }
    }
}
