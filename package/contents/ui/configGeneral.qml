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

import QtQuick 2.2
import QtQuick.Controls 1.3 as QtControls
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.0 as QtLayouts

Item {
    id: generalConfig

    property alias cfg_showSecondHand: showSecondHandCheckBox.checked
    property alias cfg_showMinuteHand: showMinuteHandCheckBox.checked

    property alias cfg_latitude: latitude.value
    property alias cfg_longitude: longitude.value

    PlasmaCore.DataSource {
        id: geolocationDS
        engine: 'geolocation'

        property string locationSource: 'location'

        connectedSources: []

        onNewData: {
            print('geolocation: ' + data.latitude)
            latitude.value = data.latitude
            longitude.value = data.longitude
        }
    }

    Column {
        QtControls.CheckBox {
            id: showSecondHandCheckBox
            text: i18n("Show seconds hand")
        }
        QtControls.CheckBox {
            id: showMinuteHandCheckBox
            text: i18n("Show minutes hand")
        }
		QtLayouts.RowLayout {
			QtControls.Label {
				text: i18n("Location (lat, long):")
			}
			QtControls.SpinBox {
				id: latitude
				decimals: 7
				stepSize: 1
				minimumValue: -90
				maximumValue: 90
			}
			QtControls.SpinBox {
				id: longitude
				decimals: 7
				stepSize: 1
				minimumValue: -180
				maximumValue: 180
			}
			QtControls.Button {
				text: i18n('Locate')
				tooltip: i18n('This will use Mozilla Location Service exposed natively in KDE')
				onClicked: {
					geolocationDS.connectedSources.length = 0
					geolocationDS.connectedSources.push(geolocationDS.locationSource)
				}
			}
		}
    }
}
