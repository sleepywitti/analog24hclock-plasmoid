cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

set(QT_MIN_VERSION "5.4.0")
set(KF5_MIN_VERSION "5.0.0")
 
find_package(ECM REQUIRED NO_MODULE)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS Plasma)
find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Quick)

plasma_install_package(package org.twitt.analog24hclock)
