/*
* Author: Rocko and CAA-Picard
* Calculates the current map illumination for a given unit
*
* Arguments:
* 0: Unit <OBJECT>
*
* Return Value:
* 0: Does the map needs shading? <BOOL>
* 1: Color of the overlay <ARRAY>
*
* Public: No
*/
#include "script_component.hpp"

EXPLODE_1_PVT(_this,_unit);

private ["_isEnclosed","_nearObjects","_light","_ll","_flashlight"];

// Blend two colors
_fnc_blendColor = {
    EXPLODE_3_PVT(_this,_c1,_c2,_alpha);
    [(_c1 select 0) * (1 - _alpha) + (_c2 select 0) * _alpha,
     (_c1 select 1) * (1 - _alpha) + (_c2 select 1) * _alpha,
     (_c1 select 2) * (1 - _alpha) + (_c2 select 2) * _alpha,
     (_c1 select 3) * (1 - _alpha) + (_c2 select 3) * _alpha]
};

// Ambient light tint depending on time of day
_lightTint = switch (true) do {
    case (sunOrMoon == 1.0) : { [0.5,0.5,0.5,1] };
    case (sunOrMoon > 0.80) : {[[1.0 - overcast,0.2,0,1], [1,1,1,1],   (sunOrMoon - 0.8)/0.2] call _fnc_blendColor};
    case (sunOrMoon > 0.50) : {[[0,0,0.1,1], [1.0 - overcast,0.2,0,1], (sunOrMoon - 0.5)/0.3] call _fnc_blendColor};
    case (sunOrMoon <= 0.5) : { [0,0,0.1,1] };
};

// Calculates overlay color from tint and light level
_fnc_calcColor = {
    EXPLODE_2_PVT(_this,_c1,_lightLevel);

    if (_lightLevel < 0.5) then {
        _l = _lightLevel / 0.5;
        [(_c1 select 0) * _l,
         (_c1 select 1) * _l,
         (_c1 select 2) * _l,
         (_c1 select 3) * (1 - _lightLevel)]
    } else {
        _l = (_lightLevel - 0.5) / 0.5;
        [(_c1 select 0) * (1 - _l) + _l,
         (_c1 select 1) * (1 - _l) + _l,
         (_c1 select 2) * (1 - _l) + _l,
         (_c1 select 3) * (1 - _lightLevel)]
    };
};

_lightLevel = 0.04 + (0.96 * call EFUNC(common,ambientBrightness));

// check if player has NVG enabled
if (currentVisionMode _unit == 1) exitWith {
    // stick to nvg color
    [true, [154/255,253/255,177/255,0.5]]
};

// Do not obscure the map if the ambient light level is above 0.95
if (_lightLevel > 0.95) exitWith {
    [false, [0.5,0.5,0.5,0]]
};

// Do not obscure the map if the player is on a enclosed vehicle (assume internal illumination)
if (vehicle _unit != _unit) then {
    // Player is in a vehicle
    if ((vehicle _unit) isKindOf "Tank") then {
        _isEnclosed = true;
    };
};
if (_isEnclosed) exitWith {
    TRACE_1("Player in a enclosed vehicle","");
    [false, [1,1,1,0]]
};

// Player is not in a vehicle
TRACE_1("Player is on foot or in an open vehicle","");

// Check if player is near a campfires, lights or vehicles with lights on - 15m
_nearObjects = [nearestObjects [_unit, ["All"], 15], {(inflamed _this) || (isLightOn _this)}] call EFUNC(common,filter);
if (count (_nearObjects) > 0) then {
    _light = _nearObjects select 0;

    _ll = (1 - (((((_unit distance _light) - 5)/10) max 0) min 1));
    if (_ll > _lightLevel) then {
        _lightLevel = _ll;
        TRACE_1("player near campfire","");
    };
};


// Gun with light
_nearObjects = [nearestObjects [_unit, ["CAManBase"], 10], { _this isFlashlightOn (currentWeapon _this)}] call EFUNC(common,filter);
if (count (_nearObjects) > 0) then {
    _light = (_nearObjects select 0);
    _flashlight = (_light weaponAccessories currentMuzzle _light) select 1;

    // Check if it's a day laser
    if (_flashlight == "ACE_acc_pointer_red") exitWith {};
    if (_flashlight == "ACE_acc_pointer_green") exitWith {};

    _lightLevel = _lightLevel max (1 - (((((_unit distance _light) - 2)/8) max 0) min 1));
    TRACE_1("Using gun light","");
};


// @todo: Illumination flares (timed)


// Using chemlights
_nearObjects = [_unit nearObjects ["SmokeShell", 4], {
    alive _this && {(typeOf _this == "Chemlight_red") || {
                    (typeOf _this == "Chemlight_green") || {
                    (typeOf _this == "Chemlight_blue") || {
                    (typeOf _this == "Chemlight_yellow")}}}}}] call EFUNC(common,filter);
if (count (_nearObjects) > 0) then {
    _light = _nearObjects select 0;

    _ll = (1 - ((((_unit distance _light) - 2)/2) max 0)) * 0.4;
    if (_ll > _lightLevel) then {
        _flareTint = switch (typeOf _light) do {
            case "Chemlight_red" : {[1,0,0,1]};
            case "Chemlight_green" : {[0,1,0,1]};
            case "Chemlight_blue" : {[0,0,1,1]};
            case "Chemlight_yellow" : {[1,1,0,1]};
        };
        _lightTint = [_lightTint, _flareTint, (_ll - _lightLevel)/(1 - _lightLevel)] call _fnc_blendColor;
        _lightLevel = _ll;
        TRACE_1("player near chemlight","");
    };
};

// Do not obscure the map if the ambient light level is above 0.95
if (_lightLevel > 0.95) exitWith {
    [false, [0.5,0.5,0.5,0]]
};

// Calculate resulting map color
[true, [_lightTint, _lightLevel] call _fnc_calcColor]
