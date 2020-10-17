/**
*   @ProjectName:       QMLPdfReader
*   @Brief：
*   @Author:            linjianpeng(lindyer)
*   @Date:              2018-11-16
*   @Note:              Copyright Reserved, Github: https://github.com/lindyer/
*/

import QtQuick 2.9
import QtQuick.Window 2.2

Window {
    visible: true
    visibility: Window.Maximized
    title: qsTr("PDF Compare")


    PdfViewer {
        id: _pdfViewer
        anchors.fill: parent
    }

    function rw(value) {
        return value;
    }

    function rh(value) {
        return value;
    }

    function rfs(value) {
        return value;
    }
}
