cmake_minimum_required(VERSION 3.16)
project(AgildoFinancas VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Sql)

if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(AgildoFinancasApp
    src/main.cpp
    src/DatabaseManager.h
    src/DatabaseManager.cpp
)

qt_add_qml_module(AgildoFinancasApp
    URI AgildoFinancas
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(AgildoFinancasApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
)

set_target_properties(AgildoFinancasApp PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)
