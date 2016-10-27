/*
 * Author: commy2, Jonpas
 * PFH for Carry Object
 *
 * Arguments:
 * 0: ARGS <ARRAY>
 *  0: Unit <OBJECT>
 *  1: Target <OBJECT>
 *  2: Start time <NUMBER>
 * 1: PFEH Id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[player, target], 20] call ace_dragging_fnc_carryObjectPFH;
 *
 * Public: No
 */
#include "script_component.hpp"

#ifdef DEBUG_ENABLED_DRAGGING
    systemChat format ["%1 carryObjectPFH running", CBA_missionTime];
#endif

params ["_args", "_idPFH"];
_args params ["_unit","_target", "_startTime", "_disabledCollisionObjects"];

if !(_unit getVariable [QGVAR(isCarrying), false]) exitWith {
    TRACE_2("carry false",_unit,_target);
    [_idPFH] call CBA_fnc_removePerFrameHandler;
};

// drop if the crate is destroyed OR (target moved away from carrier (weapon disasembled))
if (!alive _target || {_unit distance _target > 10}) then {
    TRACE_2("dead/distance",_unit,_target);
    if ((_unit distance _target > 10) && {(CBA_missionTime - _startTime) < 1}) exitWith {
        //attachTo seems to have some kind of network delay and target can return an odd position durring the first few frames,
        //so wait a full second to exit if out of range (this is critical as we would otherwise detach and set it's pos to weird pos)
        TRACE_3("ignoring bad distance at start",_unit distance _target,_startTime,CBA_missionTime);
    };
    [_unit, _target] call FUNC(dropObject_carry);
    [_idPFH] call CBA_fnc_removePerFrameHandler;
};


// Disable collision with nearby players
TRACE_1("Disable collision objects",_disabledCollisionObjects);
private _nearUnits = _target nearObjects ["CAManBase", DISABLE_COLLISION_DISTANCE];
{
    if !(_x in _disabledCollisionObjects) then {
        TRACE_2("Adding disable collision object",_x,typeOf _x);
        _target disableCollisionWith _x;
        _disabledCollisionObjects pushBack _x;
    };
} count _nearUnits;

_disabledCollisionObjects = _disabledCollisionObjects select {
    if (_x in _nearUnits) then {
        true
    } else {
        TRACE_2("Removing disable collision object",_x,typeOf _x);
        _target enableCollisionWith _x;
        false
    };
};

_args set [3, _disabledCollisionObjects];
