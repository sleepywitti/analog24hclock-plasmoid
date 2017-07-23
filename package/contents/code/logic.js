/*
 *   Copyright 2012 Viranch Mehta <viranch.mehta@gmail.com>
 *   Copyright 2012 Marco Martin <mart@kde.org>
 *   Copyright 2017 T. Witt
 *
 *   based on jSunTimes from J. M. Stott (jsuntimes@jstott.me.uk)
 *   (you can find calculation details at
 *    https://www.esrl.noaa.gov/gmd/grad/solcalc/calcdetails.html)
 *   and 24hAnalogWidget from Steve Pomeroy:
 *   (https://github.com/xxv/24hAnalogWidget)
 *   Both licenced under GNU General Public License
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
 *   You should have received a copy of the GNU Library General Public *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

var weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	
var SUNRISE_SUNSET_ZENITH_DISTANCE = 90.83333;
var CIVIL_TWILIGHT_ZENITH_DISTANCE = 96.0;
var NAUTICAL_TWILIGHT_ZENTITH_DISTANCE = 102.0;
var ASTRONOMICAL_TWILIGHT_ZENITH_DISTANCE = 108.0;

function daysInMonth(month)
{
    if (month == 2) {
        if (isLeap(year)) 
            return 29;
        else 
            return 28;
    } else if (month < 8) {
        if (month % 2 == 1) 
            return 31;
        else 
            return 30;
    } else {
        if (month % 2 == 0) 
            return 31;
        else 
            return 30;
    }
}

function isLeap(year) {
    return ((year%100==0 && year%400==0) || (year%4==0 && year%100!=0));
}

function getYear(date)
{
    return parseInt(Qt.formatDate(date, "yyyy"));
}

function getMonth(date)
{
    return parseInt(Qt.formatDate(date, "M"));
}

function getDate(date)
{
    return parseInt(Qt.formatDate(date, "d"));
}

function getWeekday(date)
{
}

function rad(x) { return x * Math.PI / 180; }
function deg(x) { return x * 180 / Math.PI; }
function sin(x) { return Math.sin(x); }
function cos(x) { return Math.cos(x); }
function tan(x) { return Math.tan(x); }
function asin(x) { return Math.asin(x); }
function acos(x) { return Math.acos(x); }

// convert Julian Day to centuries since J2000.0.
function julianDayToJulianCenturies(jd) {
    // 2451545.0 is the equivalent Julian year of Julian days for 2000
    // 0.0008 is the fractional Julian Day for leap seconds and terrestrial time.
    return (jd - 2451545.0+0.0008) / 36525.0;
}
function julianCenturiesToJulianDay(t) {
    return (t * 36525) + 2451545;
}


// Julian day from calendar date
// (Jean Meeus, "Astronomical Algorithms", Willmann-Bell, 1991)
function dateToJulian(year, month, day) {
    if (month <= 2) {
        year = year - 1;
        month = month + 12;
    }

    var B = 0;
    if (year < 1583) {  // exactly: 15.10.1582
        // julian
        B = 0;
    } else {
        // gregorian
        var A = Math.floor(year/100.0);
        B = 2 - A + Math.floor(A/4.0);
    }

    return Math.floor(365.25 * (year + 4716.0)) + Math.floor(30.6001 * (month + 1.0)) + day + B - 1524.5;
}


function convertTime(time) {
    var hours = Math.floor(time / 60.0);
    var minutes = Math.floor(time - (hours * 60));
    var seconds = Math.floor(time - minutes - (hours * 60) * 60);
    if (hours > 23)
        hours %= 24;
    return {hours: hours, 
            minutes: minutes, 
            seconds: seconds};
}

// dst = daylight savings time
function morningTime(year, month, day, lat, long, timeZone, dst, zenithDistance) {
    var julian = dateToJulian(year, month, day);
    // amount of time in milliseconds to add to UTC
    var timeZone_raw_offset = timeZone * 60 * 60 * 1000
    var timeMins = phenomenon(julian, lat, -long, zenithDistance, 1)
            + (timeZone_raw_offset / 60000.0);   
    if (dst)
        timeMins += 60.0;
    var time = convertTime(timeMins);
    return time;
}

function eveningTime(year, month, day, lat, long, timeZone, dst, zenithDistance) {
    var julian = dateToJulian(year, month, day);
    // amount of time in milliseconds to add to UTC
    var timeZone_raw_offset = timeZone * 60 * 60 * 1000
    var timeMins = phenomenon(julian, lat, -long, zenithDistance, -1)
            + (timeZone_raw_offset / 60000.0);
    if (dst)
        timeMins += 60.0;
    var time = convertTime(timeMins);
    console.log("time: " + time.hours + ":" + time.minutes);
    return time;
}

function phenomenonHelper(t, latitude, longitude, zenithDistance, hour_sign)
{
    var eqtime = equationOfTime(t);
    var solarDec = sunDeclination(t); 
    var hourangle = hour_sign * hourAngle(latitude, solarDec, zenithDistance);
    var delta = longitude - deg(hourangle);
    var timeDiff = 4. * delta;
    var timeUTC = 720. + timeDiff - eqtime;

    return timeUTC;
}

function phenomenon(julian, latitude, longitude, zenithDistance, hour_sign) {
    // longitude = -longitude;
    var t = julianDayToJulianCenturies(julian);
    var timeUTC = phenomenonHelper(t, latitude, longitude, zenithDistance, hour_sign);
    // Second pass includes fractional julian day in gamma calc
    var newt = julianDayToJulianCenturies(julianCenturiesToJulianDay(t)
            + timeUTC / 1440);
    
    timeUTC = phenomenonHelper(newt, latitude, longitude, zenithDistance, hour_sign);
    
    return timeUTC;
}


// Calculate the difference between true solar time and mean solar time
// t = Number of Julian centuries since J2000.0
function equationOfTime(t) {
    var epsilon = obliquityCorrection(t);
    var l0 = geomMeanLongSun(t);
    var e = eccentricityOfEarthsOrbit(t);
    var m = geometricMeanAnomalyOfSun(t);
    var y = Math.pow((tan(rad(epsilon) / 2)), 2);

    var Etime = y * sin(2 * rad(l0)) - 2 * e * sin(rad(m)) + 4 * e * y
            * sin(rad(m)) * cos(2 * rad(l0)) - 0.5 * y * y
            * sin(4 * rad(l0)) - 1.25 * e * e * sin(2 * rad(m));

    return deg(Etime) * 4;
}

/**
* Calculate the declination of the sun
* @param t Number of Julian centuries since J2000.0
*/
function sunDeclination(t) {
    var e = obliquityCorrection(t);
    var lambda = sunsApparentLongitude(t);

    var sint = sin(rad(e)) * sin(rad(lambda));
    return deg(asin(sint));
}

// calculate the hour angle of the sun for a morning phenomenon for the given latitude
// lat = Latitude of the observer in degrees
// solarDec = declination of the sun in degrees
// zenithDistance = zenith distance of the sun in degrees
// http://www.itacanet.org/the-sun-as-a-source-of-energy/part-3-calculating-solar-angles/
function hourAngle(lat, solarDec, zenithDistance) {
    var phi = rad(lat)
    var delta = rad(solarDec)
    return (acos(
            cos(rad(zenithDistance)) / (cos(phi) * cos(delta)) - 
            tan(phi) * tan(delta) ));
}

//Calculate the mean obliquity of the ecliptic
//   t = Number of Julian centuries since J2000.0
function obliquityCorrection(t) {
    return meanObliquityOfEcliptic(t) + 0.00256
        * cos(rad(125.04 - 1934.136 * t));
}


//Calculate the mean obliquity of the ecliptic
//   t = Number of Julian centuries since J2000.0
function meanObliquityOfEcliptic(t) {
    return 23 + (26 + (21.448 - t
        * (46.815 + t * (0.00059 - t * (0.001813))) / 60)) / 60;
}

// Calculate the geometric mean longitude of the sun
//  number = Julian centuries since J2000.0
function geomMeanLongSun(t) {
    var l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);

    // replace by modulus???
    while ((l0 >= 0) && (l0 <= 360)) {
        if (l0 > 360) {
            l0 = l0 - 360;
        }

        if (l0 < 0) {
            l0 = l0 + 360;
        }
    }

    return l0;
}

// Calculate the eccentricity of Earth's orbit
//  t = Number of Julian centuries since J2000.0
function eccentricityOfEarthsOrbit(t) {
    return 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
}

// Calculate the geometric mean anomaly of the Sun
//  t = Number of Julian centuries since J2000.0
function geometricMeanAnomalyOfSun(t) {
    return 357.52911 + t * (35999.05029 - 0.0001537 * t);
}

// Calculate the apparent longitude of the sun
//  t = Number of Julian centuries since J2000.0
function sunsApparentLongitude(t) {
    return sunsTrueLongitude(t) - 0.00569 - 0.00478
            * sin(rad(125.04 - 1934.136 * t));
}

// Calculate the true longitude of the sun
//  t = Number of Julian centuries since J2000.0
function sunsTrueLongitude(t) {
    return geomMeanLongSun(t) + equationOfCentreForSun(t);
}

// Calculate the equation of centre for the Sun
//  t = Number of Julian centuries since J2000.0
function equationOfCentreForSun(t) {
    var m = geometricMeanAnomalyOfSun(t);

    return sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * rad(m)) * (0.019993 - 0.000101 * t) + sin(3 * rad(m))
            * 0.000289;
}

function getHourHandAngle(h, m) {
    return ((12.0 + h) / 24.0 * 360.0) % 360.0 + (m / 60.0) * 360.0 / 24.0;
}

function getHourArcAngle(time) {
    return (getHourHandAngle(time.hours, time.minutes) + 270.0) % 360.0;
}
