import QtQuick 2.11
import QtQuick.Controls 2.4
import QtMultimedia 5.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4 as C1
import QtQuick.Controls.Material 2.2

ApplicationWindow {
    id: root
    visible: true
    width: 640
    height: 480
    title: "Camera Software"

    Material.theme: Material.Dark
    Material.accent: Material.Green

    property bool rounded: roundedSwitch.position === 1.0
    property bool adapt: true
    property var picturesModel: []
    property string cameraState: turnOnSwitch.position === 1.0 ? "CameraEnabled" : "CameraDisabled"

    SoundEffect {
        id: buttonSound
        source: "qrc:/button.wav"
    }
    SoundEffect {
        id: captureSound
        source: "qrc:/cameraappCapture1.wav"
    }
    SoundEffect {
        id: beepSound
        source: "qrc:/beep.wav"
    }

    function addPicture(source) {
        var image = {
            "id": source,
            "source": source
        };
        picturesModel.push(image);
        root.picturesModelChanged();
    }

    Camera {
        id: camera
        digitalZoom: zoomSlider.value
        imageProcessing.whiteBalanceMode: CameraImageProcessing.WhiteBalanceFlash
        exposure.exposureCompensation: -1.0
        exposure.exposureMode: Camera.ExposurePortrait
        flash.mode: Camera.FlashRedEyeReduction
        imageCapture.onImageCaptured: {
            addPicture(preview);
        }
    }

    C1.SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        Item {
            id: cameraControls
            width: 200
            height: parent.height

            GroupBox {
                id: controls

                label: Label {
                    text: "CONTROLS"
                    font.pointSize: 15
                    font.bold: true
                }

                width: parent.width
                height: parent.height / 2

                Column {
                    anchors.fill: parent
                    spacing: 1

                    Switch {
                        id: turnOnSwitch
                        text: "TOGGLE"
                        position: 0.0
                        onPositionChanged: {
                            buttonSound.play();
                            if (position === 1.0) {
                                camera.start();
                            }
                            else {
                                camera.stop();
                            }
                        }
                    }
                    Switch {
                        id: roundedSwitch
                        text: "CIRCULAR"
                        position: 0.0
                        onPositionChanged: {
                            buttonSound.play();
                        }
                    }

                    Image {
                        source: "qrc:/save.png"
                        sourceSize.width: 55
                        sourceSize.height: 55
                        fillMode: Image.PreserveAspectCrop
                        width: 55
                        height: 55
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                beepSound.play();
                                MyImageSave.writePictures();
                            }
                        }
                    }
                }
            }
            VideoOutput {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: controls.bottom
                height: parent.height / 2 - 50
                source: camera
                focus: visible

                Rectangle {
                    id: captureButton1
                    width: 55
                    height: 55
                    radius: 50
                    color: "red"
                    border.width: 2
                    border.color: "lime"
                    opacity: 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            captureButton1.color = "lime";
                            camera.imageCapture.capture();
                            captureSound.play();
                        }
                        onReleased: {
                            captureButton1.color = "red";
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    visible: cameraState === "CameraDisabled"
                    Image {
                        source: "qrc:/disabled.png"
                        sourceSize.width: parent.width / 2
                        sourceSize.height: parent.height / 2
                        width: parent.width / 2
                        height: parent.height / 2
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                    }
                }
            }
            Slider {
                id: zoomSilder
                orientation: Qt.Horizontal
                from: 0
                to: camera.maximumDigitalZoom
                stepSize: camera.maximumDigitalZoom / 10
                value: 1.0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }

        }

        Item {
            id: picturesModel
            height: parent.height
            Rectangle {
                anchors.fill: parent
                color: "gray"
                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: parent.width / 5
                    cellHeight: parent.height / 5
                    model: picturesModel
                    delegate: Rectangle {
                        property bool showPicture: true

                        id: rect
                        width: grid.cellWidth
                        height: grid.cellHeight
                        color: showPicture ? "transparent" : "white"
                        radius: rounded ? 200 : 0

                        Text {
                            anchors.centerIn: parent
                            visible: !rect.showPicture
                            font.pointSize: 60
                            text: {
                                var txt = modelData.id;
                                txt = txt.substring(txt.indexOf("_") + 1);
                                return txt;
                            }
                        }

                        Image {
                            id: image
                            visible: rect.showPicture
                            anchors.centerIn: parent
                            source: modelData.source
                            sourceSize.width: 512
                            sourceSize.height: 512
                            width: parent.width * 0.95
                            height: parent.height * 0.95
                            fillMode: Image.PreserveAspectCrop

                            layer.enabled: rounded
                            layer.effect: ShaderEffect {
                                property real adjustX: adapt ? Math.max(width/height, 1) : 1
                                property real adjustY: adapt ? Math.max(1/(width/height), 1) : 1
                                fragmentShader: "
                                        #ifdef GL_ES
                                            precision lowp float;
                                        #endif // GL_ES
                                        varying highp vec2 qt_TextCoord0;
                                        uniform highp float qt_Opacity;
                                        uniform lowp sampler2D source;
                                        uniform lowp float adjustX;
                                        uniform lowp float adjustY;

                                        void main(void) {
                                            lowp float x, y;
                                            x = (qt_TextCoord0.x - 0.5) * adjustX;
                                            y = (qt_TextCoord0.y - 0.5) * adjustY;
                                            float delta = adjustX != 1.0 ? fwidth(y) / 2.0 : fwidth(x) / 2.0;
                                            gl_FragColor = texture2D(source, qt_TextCoord0).rgba
                                                * step(x * x + y * y, 0.25)
                                                * smoothstep((x * x + y * y), 0.25 + delta, 0.25)
                                                * qt_Opacity;
                                            }"
                            }

                            Component.onCompleted: {
                                image.grabToImage(function(result) {
                                    MyImageSave.savePicture(modelData.id, result);
                                });
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                rect.showPicture = false;
                            }
                            onExited: {
                                rect.showPicture = true;
                            }
                        }
                    }
                }
            }

        }
    }
}
