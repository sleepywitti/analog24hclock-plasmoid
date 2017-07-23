/*
 *   Copyright 2012 Viranch Mehta <viranch.mehta@gmail.com>
 *   Copyright 2012 Marco Martin <mart@kde.org>
 *   Copyright 2013 David Edmundson <davidedmundson@kde.org>
 *   Copyright 2017 T. Witt
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.calendar 2.0 as PlasmaCalendar
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import "logic.js" as Logic

Item {
    id: analogclock

    width: units.gridUnit * 15
    height: units.gridUnit * 15
    property int hours
    property int minutes
    property int seconds
    property int lastDay
    property int lastTzOffset

    property real morningSunAngle
    property real morningCivAngle
    property real morningNauAngle
    property real morningAstAngle
    property real eveningSunAngle
    property real eveningCivAngle
    property real eveningNauAngle
    property real eveningAstAngle
    property real highNoon

    property bool showSecondsHand: plasmoid.configuration.showSecondHand
    property bool showMinutesHand: plasmoid.configuration.showMinuteHand
    property real latitude: plasmoid.configuration.latitude
    property real longitude: plasmoid.configuration.longitude
    property int tzOffset

    Plasmoid.backgroundHints: "NoBackground";
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.toolTipMainText: Qt.formatDate(dataSource.data["Local"]["DateTime"],"dddd")
    Plasmoid.toolTipSubText: Qt.formatDate(dataSource.data["Local"]["DateTime"], Qt.locale().dateFormat(Locale.LongFormat).replace(/(^dddd.?\s)|(,?\sdddd$)/, ""))

    PlasmaCore.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: "Local"
        interval: showSecondsHand ? 1000 : 30000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"]);
            var mn = date.getMonth() + 1;
            var dn = date.getDate();
            var year = date.getFullYear();

            hours = date.getHours();
            minutes = date.getMinutes();
            seconds = date.getSeconds();

            if (lastDay != dn || lastTzOffset != tzOffset) {
                var lat = latitude;
                var lon = longitude;
                var tzo = date.getTimezoneOffset() / (-60);


                morningSunAngle = Logic.rad(Logic.getHourArcAngle(Logic.morningTime(year, mn, dn, lat, lon,  tzo, false, Logic.SUNRISE_SUNSET_ZENITH_DISTANCE)));
                morningCivAngle = Logic.rad(Logic.getHourArcAngle(Logic.morningTime(year, mn, dn, lat, lon,  tzo, false, Logic.CIVIL_TWILIGHT_ZENITH_DISTANCE)));
                morningNauAngle = Logic.rad(Logic.getHourArcAngle(Logic.morningTime(year, mn, dn, lat, lon,  tzo, false, Logic.NAUTICAL_TWILIGHT_ZENTITH_DISTANCE)));
                morningAstAngle = Logic.rad(Logic.getHourArcAngle(Logic.morningTime(year, mn, dn, lat, lon,  tzo, false, Logic.ASTRONOMICAL_TWILIGHT_ZENITH_DISTANCE)));
                eveningSunAngle = Logic.rad(Logic.getHourArcAngle(Logic.eveningTime(year, mn, dn, lat, lon,  tzo, false, Logic.SUNRISE_SUNSET_ZENITH_DISTANCE)));
                eveningCivAngle = Logic.rad(Logic.getHourArcAngle(Logic.eveningTime(year, mn, dn, lat, lon,  tzo, false, Logic.CIVIL_TWILIGHT_ZENITH_DISTANCE)));
                eveningNauAngle = Logic.rad(Logic.getHourArcAngle(Logic.eveningTime(year, mn, dn, lat, lon,  tzo, false, Logic.NAUTICAL_TWILIGHT_ZENTITH_DISTANCE)));
                eveningAstAngle = Logic.rad(Logic.getHourArcAngle(Logic.eveningTime(year, mn, dn, lat, lon,  tzo, false, Logic.ASTRONOMICAL_TWILIGHT_ZENITH_DISTANCE)));

                highNoon = Logic.rad((360 + Logic.deg(morningSunAngle) + ((360 + Logic.deg(eveningSunAngle - morningSunAngle)) % 360) * 0.5) % 360);

                lastDay = dn
                lastTzOffset = tzOffset
            }

        }
        Component.onCompleted: {
            onDataChanged();
        }
    }

    function dateTimeChanged()
    {
        var currentTZOffset = dataSource.data["Local"]["Offset"] / 60;
        if (currentTZOffset != tzOffset) {
            tzOffset = currentTZOffset;
            Date.timeZoneUpdated(); // inform the QML JS engine about TZ change
        }
    }

    Component.onCompleted: {
        tzOffset = new Date().getTimezoneOffset();
        //console.log("Initial TZ offset: " + tzOffset);
        dataSource.onDataChanged.connect(dateTimeChanged);
    }

    Plasmoid.compactRepresentation: Item {
        id: representation
        Layout.minimumWidth: plasmoid.formFactor != PlasmaCore.Types.Vertical ? representation.height : units.gridUnit
        Layout.minimumHeight: plasmoid.formFactor == PlasmaCore.Types.Vertical ? representation.width : units.gridUnit

        MouseArea {
            anchors.fill: parent
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }


        PlasmaCore.Svg {
            id: clockSvg
            //imagePath: "widgets/clock"
            imagePath: plasmoid.file("ui", "myclock.svgz")
        }

        Item {
            id: clock
            width: parent.width
            z: 1
            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            PlasmaCore.SvgItem {
                id: face
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: Math.min(parent.width, parent.height)
                svg: clockSvg
                elementId: "ClockFace"
            }

            PlasmaCore.SvgItem {
                anchors.fill: face
                svg: clockSvg
                elementId: "Glass"
                width: naturalSize.width * face.width / face.naturalSize.width
                height: naturalSize.height * face.width / face.naturalSize.width
            }
        }

        Canvas {
            id: canvas
            anchors.centerIn: clock
            z: 2
            width: Math.min(parent.width, parent.height)/1.45
            height: Math.min(parent.width, parent.height)/1.45
            onPaint: {
                var radius = Math.min(parent.width, parent.height)/2.9
                var ctx = getContext("2d")
                ctx.fillStyle = Qt.rgba(0.095, 0.105, 0.15, 0.3)
                ctx.beginPath()
                ctx.moveTo(radius, radius);
                ctx.arc(radius, radius, radius, eveningSunAngle, morningSunAngle)
                ctx.fill()

                ctx.fillStyle = Qt.rgba(0.0, 0.0, 0.0, 0.1)
                ctx.beginPath()
                ctx.moveTo(radius, radius)
                ctx.arc(radius, radius, radius, eveningCivAngle, morningCivAngle)
                ctx.fill()

                if ((eveningNauAngle > 0) && (morningNauAngle > 0)) {
                    ctx.fillStyle = Qt.rgba(0.0, 0.0, 0.0, 0.1)
                    ctx.beginPath()
                    ctx.moveTo(radius, radius)
                    ctx.arc(radius, radius, radius, eveningNauAngle, morningNauAngle)
                    ctx.fill()
                }

                if ((eveningAstAngle > 0) && (morningAstAngle > 0)) {
                    ctx.fillStyle = Qt.rgba(0.0, 0.0, 0.0, 0.1)
                    ctx.beginPath()
                    ctx.moveTo(radius, radius)
                    ctx.arc(radius, radius, radius, eveningAstAngle, morningAstAngle)
                    ctx.fill()
                }

                /* ctx.fillStyle = Qt.rgba(0.0, 0.0, 0.0, 0.1) */
                ctx.fillStyle = Qt.rgba(0.8, 0.6, 0.0, 0.6);
                ctx.beginPath()
                ctx.moveTo(radius, radius)
                ctx.arc(radius, radius, radius, highNoon-0.02, highNoon+0.02)
                ctx.fill()

                /* ctx.beginPath() */
                /* ctx.moveTo(radius, radius); */
                /* ctx.lineTo(radius+Math.cos(highNoon) * 0.85 * radius, */
                /*            radius+Math.sin(highNoon) * 0.85 * radius); */
                /* ctx.lineWidth = radius * 0.012; */
                /* ctx.stroke(); */
            }
        }
        Hand {
            elementId: "HourHand"
            z: 3
            rotation: (hours * 15 + (minutes/4))
            svgScale: face.width / face.naturalSize.width
        }

        Hand {
            elementId: "MinuteHand"
            z: 4
            rotation: 180 + minutes * 6
            visible: showMinutesHand
            svgScale: face.width / face.naturalSize.width
        }

        Hand {
            elementId: "SecondHand"
            z: 5
            rotation: 180 + seconds * 6
            visible: showSecondsHand
            svgScale: face.width / face.naturalSize.width
        }

        PlasmaCore.SvgItem {
            id: center
            z: 10
            width: naturalSize.width * face.width / face.naturalSize.width
            height: naturalSize.height * face.width / face.naturalSize.width
            anchors.centerIn: clock
            svg: clockSvg
            elementId: "HandCenterScrew"
        }
    }
    Plasmoid.fullRepresentation: PlasmaCalendar.MonthView {
        Layout.minimumWidth: units.gridUnit * 20
        Layout.minimumHeight: units.gridUnit * 20

        today: dataSource.data["Local"]["DateTime"]
    }

}
