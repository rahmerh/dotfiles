import QtQuick 2.15
import SddmComponents 2.0
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 640
    height: 480
    color: "#000000"

    readonly property int usernameRole: Qt.UserRole + 1
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool loginFailed: false
    property bool authenticating: false
    readonly property string fieldFontFamily: "JetBrainsMono Nerd Font Mono"

    function currentUsername() {
        return userModel.data(userModel.index(userIndex, 0), usernameRole)
    }

    function login() {
        if (username.text.length > 0 && password.text.length > 0) {
            root.authenticating = true
            sddm.login(username.text, password.text, sessionIndex)
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            password.clear()
            root.loginFailed = true
            root.authenticating = false
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.authenticating = false
        }

        function onInformationMessage(message) {
            root.authenticating = true
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.stringValue("background")
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    RecursiveBlur {
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: config.intValue("blurSize") || 6
        loops: config.intValue("blurPasses") || 2
    }

    Item {
        id: primaryScreen
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        Rectangle {
            id: usernameField
            x: passwordField.x
            y: passwordField.y - height - 10
            width: passwordField.width
            height: passwordField.height
            color: "#a6000000"

            Rectangle {
                width: 10
                height: parent.height
                color: "#e1579c"
            }

            TextInput {
                id: username
                x: 28
                width: parent.width - x
                height: parent.height
                color: "#ffffff"
                text: userModel.lastUser || root.currentUsername()
                font.family: root.fieldFontFamily
                font.pixelSize: 24
                horizontalAlignment: TextInput.AlignLeft
                verticalAlignment: TextInput.AlignVCenter
                cursorVisible: activeFocus
                clip: true
                KeyNavigation.backtab: password
                KeyNavigation.tab: password

                onAccepted: password.forceActiveFocus()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: username.forceActiveFocus()
            }
        }

        Rectangle {
            id: passwordField
            x: 40
            y: parent.height - height - (parent.height * 0.05)
            width: 420
            height: 70
            color: "#a6000000"

            Rectangle {
                width: 10
                height: parent.height
                color: root.loginFailed ? "#ff3117"
                    : root.authenticating ? "#ffffff"
                    : "#e1579c"

                SequentialAnimation on opacity {
                    running: root.authenticating && !root.loginFailed
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.35; duration: 550 }
                    NumberAnimation { from: 0.35; to: 1; duration: 550 }
                }
            }

            TextInput {
                id: password
                x: 28
                width: parent.width - x
                height: parent.height
                color: "#ffffff"
                echoMode: TextInput.Password
                font.family: root.fieldFontFamily
                font.pixelSize: 24
                font.letterSpacing: 3
                horizontalAlignment: TextInput.AlignLeft
                verticalAlignment: TextInput.AlignVCenter
                cursorVisible: activeFocus
                clip: true
                focus: true
                KeyNavigation.backtab: username
                KeyNavigation.tab: username

                onAccepted: root.login()
                onTextEdited: {
                    root.loginFailed = false
                    root.authenticating = false
                }
                Component.onCompleted: forceActiveFocus()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: password.forceActiveFocus()
            }
        }
    }

    Loader {
        active: config.boolValue("hideCursor")
        anchors.fill: parent
        sourceComponent: MouseArea {
            enabled: false
            cursorShape: Qt.BlankCursor
        }
    }
}
