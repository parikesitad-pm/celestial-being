import QtQuick
import "../atoms"
import "../molecules"

// The stack shared by the login and lock screens: avatar, date, clock, password field.
Item {
    id: stack

    property date now
    property string user
    property url avatar
    property bool capsLock: false
    readonly property alias field: passwordField

    signal keyed(real x, real y)
    signal submitted()

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 340
        gradient: Gradient {
            GradientStop { position: 0; color: "#00070b14" }
            GradientStop { position: 0.35; color: Tokens.scrim }
            GradientStop { position: 1; color: Tokens.scrim }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passwordField.forceActiveFocus()
    }

    Rise {
        delay: 500
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 330 }
        Avatar { source: stack.avatar }
    }

    Rise {
        delay: 560
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 270 }
        Text {
            text: Qt.formatDate(stack.now, "dddd, dd MMMM")
            color: "#cce8f1ff"
            font { family: Tokens.sans; pixelSize: 20 }
        }
    }

    Rise {
        delay: 620
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 160 }
        RollingClock { time: stack.now }
    }

    Rise {
        delay: 680
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 70 }
        PasswordField {
            id: passwordField
            focus: true
            placeholder: stack.user
            capsLock: stack.capsLock
            onKeyed: {
                const spot = mapToItem(stack, width / 2 + (Math.random() - 0.5) * 200, 0)
                stack.keyed(spot.x, spot.y)
            }
            onSubmitted: stack.submitted()
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
        text: "d-ap.my.id"
        color: "#77e8f1ff"
        font { family: Tokens.mono; pixelSize: 12 }
    }
}
