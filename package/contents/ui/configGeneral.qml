/*
 *  Copyright 2013 David Edmundson <davidedmundson@kde.org>
 *  Copyright 2017 T. Witt
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */


import QtQuick
import QtQuick.Controls as QtControls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
//import org.kde.plasma.core 2.0 as PlasmaCore
//import QtQuick.Layouts 1.0 as QtLayouts
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.plasma.components as PlasmaComponents3

KCM.SimpleKCM {
    id: config_container

    property alias cfg_showSecondHand: showSecondHand.checked
    property alias cfg_showMinuteHand: showMinuteHand.checked
    property alias cfg_latitude: latitude.text
    property alias cfg_longitude: longitude.text

    property alias cfg_showSecondHandDefault: showSecondHand.checked
    property alias cfg_showMinuteHandDefault: showMinuteHand.checked
    property alias cfg_latitudeDefault: latitude.text
    property alias cfg_longitudeDefault: longitude.text

    FormCard.FormCardPage {
        id: page

        FormCard.FormHeader {
            title: i18n("Display")
        }

        Kirigami.FormLayout {
            QtControls.CheckBox {
                id: showSecondHand
                text: i18n("Show minutes hand")
            }

            QtControls.CheckBox {
                id: showMinuteHand
                text: i18n("Show seconds hand")
            }
        }

        FormCard.FormHeader {
            title: i18n("Position")
        }

        Kirigami.FormLayout {
            PlasmaComponents3.TextField {
                Kirigami.FormData.label: "Latitude:"
                id: latitude
                placeholderText: i18n("Latitude")
                property int decimals: 7
                validator: DoubleValidator {bottom: -90; top: 90; decimals: decimals;}
                property real realValue: 0
            }
            PlasmaComponents3.TextField {
                Kirigami.FormData.label: "Longitude:"
                id: longitude
                placeholderText: i18n("Longitude")
                property int decimals: 7
                validator: DoubleValidator {bottom: -180; top: 180; decimals: decimals;}
                property real realValue: 0
            }
        }
    }
}
